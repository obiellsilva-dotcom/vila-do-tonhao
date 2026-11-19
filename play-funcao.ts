// Edge Function "play": confere compras feitas pelo Google Play (dentro do app) e libera o item.
// Segredo necessário (Edge Functions > Secrets): GOOGLE_SA_JSON = conteúdo inteiro do arquivo .json da conta de serviço
// (Google Cloud) que foi convidada no Play Console com permissão de "Ver dados financeiros" e "Gerenciar pedidos".
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const PACOTE = "br.com.viladotonhao.app";
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });
const admin = createClient(SB_URL, SERVICE);

// ---- login no Google com a conta de serviço (JWT assinado RS256) ----
let tokenGoogle = { v: "", ate: 0 };
const b64u = (b: ArrayBuffer | Uint8Array | string) => {
  const by = typeof b === "string" ? new TextEncoder().encode(b) : new Uint8Array(b as ArrayBuffer);
  let s = ""; by.forEach((x) => s += String.fromCharCode(x));
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
};
async function google() {
  if (tokenGoogle.v && Date.now() < tokenGoogle.ate) return tokenGoogle.v;
  const sa = JSON.parse(Deno.env.get("GOOGLE_SA_JSON") || "{}");
  if (!sa.private_key) throw new Error("Falta o segredo GOOGLE_SA_JSON.");
  const agora = Math.floor(Date.now() / 1000);
  const corpo = b64u(JSON.stringify({ alg: "RS256", typ: "JWT" })) + "." + b64u(JSON.stringify({
    iss: sa.client_email, scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: "https://oauth2.googleapis.com/token", iat: agora, exp: agora + 3600,
  }));
  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const chave = await crypto.subtle.importKey("pkcs8", der, { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const ass = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", chave, new TextEncoder().encode(corpo));
  const r = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST", headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: "grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=" + corpo + "." + b64u(ass),
  });
  const j = await r.json();
  if (!j.access_token) { console.error("google token", JSON.stringify(j)); throw new Error("Não consegui falar com o Google."); }
  tokenGoogle = { v: j.access_token, ate: Date.now() + 50 * 60e3 };
  return j.access_token;
}
async function gp(caminho: string, metodo = "GET") {
  const r = await fetch(`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACOTE}/purchases/products/${caminho}`, {
    method: metodo, headers: { Authorization: "Bearer " + await google() },
  });
  const t = await r.text();
  if (!r.ok) { console.error("play", metodo, caminho.split("/tokens/")[0], r.status, t); throw new Error("Compra não encontrada no Google Play."); }
  return t ? JSON.parse(t) : {};
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  try {
    const auth = req.headers.get("Authorization") || "";
    const user = createClient(SB_URL, ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user: eu } } = await user.auth.getUser();
    if (!eu) return json({ erro: "Entre no jogo primeiro." }, 401);
    const { sku, token } = await req.json();
    if (typeof sku !== "string" || typeof token !== "string" || token.length < 20 || token.length > 4000) return json({ erro: "Compra inválida." }, 400);

    // produto do jogo com o mesmo código (no Google o código é minúsculo: passe_T1 vira passe_t1)
    const { data: prods } = await admin.from("produtos").select("*");
    const pr = (prods || []).find((p: any) => p.id.toLowerCase() === sku.toLowerCase());
    if (!pr) return json({ erro: "Produto não encontrado." }, 400);

    const mpId = "gp:" + token.slice(0, 180);
    const { data: ja } = await admin.from("pedidos").select("id,status,morador").eq("mp_id", mpId).maybeSingle();
    if (ja && ja.status === "entregue") return json({ ok: true, ja: true, consumir: ["vip", "dinheiro"].includes(pr.tipo) });

    // confere no Google Play se a compra existe e está paga (não confia no app)
    const c = await gp(`${encodeURIComponent(sku)}/tokens/${encodeURIComponent(token)}`);
    if (c.purchaseState !== 0) return json({ erro: "Pagamento ainda não confirmado pelo Google." }, 402);

    let pid = ja?.id;
    if (!pid) {
      const { data: pd, error } = await admin.from("pedidos").insert({ morador: eu.id, produto: pr.id, valor: pr.preco }).select().single();
      if (error) return json({ erro: error.message }, 400);
      pid = pd.id;
    }
    const { error: e2 } = await admin.rpc("_entregar", { p_pedido: pid, p_mp_id: mpId, p_valor: pr.preco });
    if (e2) { console.error("entregar", JSON.stringify(e2)); return json({ erro: "Não consegui entregar o item." }, 500); }

    const consumir = ["vip", "dinheiro"].includes(pr.tipo); // estes podem ser comprados de novo
    try {
      if (consumir) await gp(`${encodeURIComponent(sku)}/tokens/${encodeURIComponent(token)}:consume`, "POST");
      else if (c.acknowledgementState !== 1) await gp(`${encodeURIComponent(sku)}/tokens/${encodeURIComponent(token)}:acknowledge`, "POST");
    } catch (e) { console.error("ack/consume", e); }
    return json({ ok: true, consumir });
  } catch (e) {
    console.error(e);
    return json({ erro: (e as Error).message || "Erro" }, 500);
  }
});
