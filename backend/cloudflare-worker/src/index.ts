interface Env {
  APP_NAME: string;
  AUTH_JWT_SECRET: string;
  UPLOAD_TOKEN_SECRET: string;
  PUBLIC_ASSET_BASE_URL?: string;
  UPLOAD_BUCKET?: R2Bucket;
}

type LoginBody = {
  email?: string;
  password?: string;
};

type PresignBody = {
  filename?: string;
  mimeType?: string;
  byteLength?: number;
  listingDraftId?: string;
};

type UploadTokenClaims = {
  sub: string;
  key: string;
  mimeType: string;
  exp: number;
};

const json = (status: number, payload: unknown): Response =>
  new Response(JSON.stringify(payload), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });

const parseJSON = async <T>(request: Request): Promise<T | null> => {
  try {
    return (await request.json()) as T;
  } catch {
    return null;
  }
};

const encoder = new TextEncoder();
const decoder = new TextDecoder();

const toBase64URL = (input: Uint8Array | string): string => {
  const bytes = typeof input === "string" ? encoder.encode(input) : input;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
};

const fromBase64URL = (input: string): Uint8Array => {
  const normalized = input.replace(/-/g, "+").replace(/_/g, "/");
  const padded = normalized + "=".repeat((4 - (normalized.length % 4)) % 4);
  const binary = atob(padded);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
};

const importHMACKey = async (secret: string): Promise<CryptoKey> =>
  crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"]
  );

const signHS256 = async (payload: Record<string, unknown>, secret: string): Promise<string> => {
  const header = { alg: "HS256", typ: "JWT" };
  const encodedHeader = toBase64URL(JSON.stringify(header));
  const encodedPayload = toBase64URL(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const key = await importHMACKey(secret);
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(signingInput));
  return `${signingInput}.${toBase64URL(new Uint8Array(signature))}`;
};

const verifyHS256 = async (token: string, secret: string): Promise<Record<string, unknown> | null> => {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  const [encodedHeader, encodedPayload, encodedSig] = parts;
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const key = await importHMACKey(secret);
  const isValid = await crypto.subtle.verify(
    "HMAC",
    key,
    fromBase64URL(encodedSig),
    encoder.encode(signingInput)
  );
  if (!isValid) return null;
  try {
    const payloadJSON = decoder.decode(fromBase64URL(encodedPayload));
    const payload = JSON.parse(payloadJSON) as Record<string, unknown>;
    const exp = typeof payload.exp === "number" ? payload.exp : 0;
    if (Date.now() / 1000 >= exp) return null;
    return payload;
  } catch {
    return null;
  }
};

const sanitizeFilename = (value: string): string =>
  value
    .replace(/[^a-zA-Z0-9._-]/g, "_")
    .replace(/_+/g, "_")
    .slice(0, 120);

const parseBearer = (request: Request): string | null => {
  const auth = request.headers.get("authorization");
  if (!auth) return null;
  const [scheme, token] = auth.split(" ");
  if (scheme?.toLowerCase() !== "bearer" || !token) return null;
  return token.trim();
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, "") || "/";

    if (request.method === "GET" && (path === "/health" || path === "/healthz" || path === "/status" || path === "/v1/health")) {
      return json(200, {
        ok: true,
        service: env.APP_NAME ?? "AfricanFashionApp",
        timestamp: new Date().toISOString(),
      });
    }

    if (request.method === "POST" && (path === "/v1/auth/login" || path === "/auth/login" || path === "/login")) {
      const body = await parseJSON<LoginBody>(request);
      if (!body?.email || !body?.password) {
        return json(400, { message: "Email and password are required." });
      }
      if (body.password.length < 8) {
        return json(401, { message: "Invalid credentials." });
      }
      const displayName = body.email.split("@")[0] || "Guest";
      const now = Math.floor(Date.now() / 1000);
      const token = await signHS256(
        {
          sub: body.email,
          displayName,
          iat: now,
          exp: now + 60 * 60,
          aud: env.APP_NAME ?? "AfricanFashionApp",
        },
        env.AUTH_JWT_SECRET
      );
      return json(200, {
        accessToken: token,
        user: {
          email: body.email,
          displayName,
        },
      });
    }

    if (request.method === "POST" && path === "/v1/uploads/presign") {
      const bearer = parseBearer(request);
      if (!bearer) {
        return json(401, { message: "Missing bearer token." });
      }
      const authClaims = await verifyHS256(bearer, env.AUTH_JWT_SECRET);
      if (!authClaims || typeof authClaims.sub !== "string") {
        return json(401, { message: "Invalid bearer token." });
      }
      const body = await parseJSON<PresignBody>(request);
      if (!body?.filename || !body?.mimeType || !body?.byteLength) {
        return json(400, { message: "filename, mimeType, and byteLength are required." });
      }

      const safeName = sanitizeFilename(body.filename);
      const key = `uploads/${crypto.randomUUID()}/${safeName}`;
      const now = Math.floor(Date.now() / 1000);
      const uploadToken = await signHS256(
        {
          sub: authClaims.sub,
          key,
          mimeType: body.mimeType,
          exp: now + 60 * 15,
        } satisfies UploadTokenClaims,
        env.UPLOAD_TOKEN_SECRET
      );
      const uploadURL = `${url.origin}/v1/uploads/direct/${encodeURIComponent(key)}?token=${encodeURIComponent(uploadToken)}`;
      const publicBase = env.PUBLIC_ASSET_BASE_URL?.trim();
      const publicURL = publicBase
        ? `${publicBase.replace(/\/+$/, "")}/${key}`
        : null;

      return json(200, {
        uploadURL,
        method: "PUT",
        headers: {
          "content-type": body.mimeType,
        },
        objectKey: key,
        expiresInSeconds: 900,
        listingDraftId: body.listingDraftId ?? null,
        publicURL,
      });
    }

    if (request.method === "PUT" && path.startsWith("/v1/uploads/direct/")) {
      const key = decodeURIComponent(path.replace("/v1/uploads/direct/", ""));
      const token = url.searchParams.get("token");
      if (!token) {
        return json(401, { message: "Missing upload token." });
      }
      const tokenClaims = await verifyHS256(token, env.UPLOAD_TOKEN_SECRET);
      if (
        !tokenClaims ||
        typeof tokenClaims.key !== "string" ||
        tokenClaims.key !== key ||
        typeof tokenClaims.mimeType !== "string"
      ) {
        return json(401, { message: "Invalid upload token." });
      }

      const contentType = request.headers.get("content-type") || "";
      if (!contentType.toLowerCase().startsWith((tokenClaims.mimeType as string).toLowerCase())) {
        return json(400, { message: "Content-Type mismatch." });
      }

      const buffer = await request.arrayBuffer();
      if (buffer.byteLength === 0) {
        return json(400, { message: "Upload body is empty." });
      }

      if (!env.UPLOAD_BUCKET) {
        return json(503, {
          message: "R2 is not configured for this Worker. Enable R2 and add bucket binding UPLOAD_BUCKET.",
          objectKey: key,
        });
      }

      await env.UPLOAD_BUCKET.put(key, buffer, {
        httpMetadata: { contentType },
      });

      const publicBase = env.PUBLIC_ASSET_BASE_URL?.trim();
      const publicURL = publicBase
        ? `${publicBase.replace(/\/+$/, "")}/${key}`
        : null;
      return json(200, {
        ok: true,
        objectKey: key,
        byteLength: buffer.byteLength,
        publicURL,
      });
    }

    return json(404, { message: `Route not found: ${request.method} ${path}` });
  },
};
