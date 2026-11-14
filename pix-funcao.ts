// Edge Function "pix": gera o Pix pela API de Orders do Mercado Pago e libera o item quando o pagamento cai.
// Segredo necessário (Edge Functions > Secrets): MP_ACCESS_TOKEN = Access Token de PRODUÇÃO do Mercado Pago.
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SB_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const MP = Deno.env.get("MP_ACCESS_TOKEN")!;
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) => new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });
const admin = createClient(SB_URL, SERVICE);

async function mp(path: string, init: RequestInit = {}) {
  const r = await fetch("https://api.mercadopago.com" + path, {
    ...init, headers: { Authorization: "Bearer " + MP, "Content-Type": "application/json", ...(init.headers || {}) },
  });
  const j = await r.json().catch(() => ({}));
  if (!r.ok) { console.error("MP", r.status, JSON.stringify(j)); throw new Error(j.message || "Erro no Mercado Pago"); }
  return j;
}

// Confere a order direto no Mercado Pago e, se estiver paga, entrega o item. Devolve true se entregou/já estava entregue.
async function conferir(orderId: string) {
  const o = await mp("/v1/orders/" + orderId);
  const pgs = o.transactions?.payments || [];
  const ok = (x: any) => ["processed", "approved", "paid", "accredited"].includes(String(x || "").toLowerCase());
  const pago = ok(o.status) || ok(o.status_detail) || pgs.some((p: any) => ok(p.status) || ok(p.status_detail));
  console.log("conferir", orderId, "order:", o.status, o.status_detail, "pagamentos:", JSON.stringify(pgs.map((p: any) => [p.status, p.status_detail, p.amount, p.paid_amount])));
  if (!pago || !o.external_reference) return false;
  const valor = Number(o.total_paid_amount || pgs[0]?.paid_amount || pgs[0]?.amount || o.total_amount);
  const { error } = await admin.rpc("_entregar", { p_pedido: o.external_reference, p_mp_id: String(o.id), p_valor: valor });
  if (error) { console.error("entregar falhou", JSON.stringify(error)); return false; }
  return true;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  const u = new URL(req.url);

  // 1) Aviso (webhook) do Mercado Pago: não confia no aviso, confere direto no Mercado Pago.
  if (u.searchParams.get("webhook")) {
    try {
      let id = u.searchParams.get("data.id") || u.searchParams.get("id");
      if (!id) { try { const b = await req.json(); id = b?.data?.id; } catch (_) { /* sem corpo */ } }
      if (id) await conferir(String(id));
    } catch (e) { console.error("webhook", e); }
    return new Response("ok");
  }

  try {
    const auth = req.headers.get("Authorization") || "";
    const user = createClient(SB_URL, ANON, { global: { headers: { Authorization: auth } } });
    const { data: { user: eu } } = await user.auth.getUser();
    if (!eu || eu.is_anonymous || !eu.email) return json({ erro: "Entre com sua conta para comprar." }, 401);
    const body = await req.json();

    // 2) O jogo perguntando se o pedido já foi pago (funciona mesmo se o aviso do Mercado Pago atrasar)
    if (body.verificar) {
      const { data: pd } = await admin.from("pedidos").select("id,status,mp_id,morador").eq("id", body.verificar).maybeSingle();
      if (!pd || pd.morador !== eu.id) return json({ erro: "Pedido não encontrado." }, 404);
      if (pd.status !== "entregue" && pd.mp_id) await conferir(pd.mp_id);
      const { data: atual } = await admin.from("pedidos").select("status").eq("id", pd.id).single();
      return json({ status: atual?.status });
    }

    // 3) Jogador pedindo um Pix novo
    const { data: pr } = await admin.from("produtos").select("*").eq("id", body.produto).maybeSingle();
    if (!pr) return json({ erro: "Produto não encontrado." }, 400);
    const { data: m } = await admin.from("moradores").select("id,pets,carros,banido").eq("id", eu.id).maybeSingle();
    if (!m || m.banido) return json({ erro: "Crie seu morador primeiro." }, 400);
    if (pr.tipo === "pet" && (m.pets || []).includes(pr.item)) return json({ erro: "Você já tem esse pet." }, 400);
    if (pr.tipo === "carro" && (m.carros || []).includes(pr.item)) return json({ erro: "Você já tem esse carro." }, 400);

    const { data: pd, error } = await admin.from("pedidos").insert({ morador: eu.id, produto: pr.id, valor: pr.preco }).select().single();
    if (error) throw error;
    const valor = Number(pr.preco).toFixed(2);
    const o = await mp("/v1/orders", {
      method: "POST",
      headers: { "X-Idempotency-Key": pd.id },
      body: JSON.stringify({
        type: "online",
        processing_mode: "automatic",
        external_reference: pd.id,
        total_amount: valor,
        description: "Cidade do Tonhão - " + pr.nome,
        payer: { email: eu.email },
        transactions: { payments: [{ amount: valor, payment_method: { id: "pix", type: "bank_transfer" }, expiration_time: "PT30M" }] },
      }),
    });
    await admin.from("pedidos").update({ mp_id: String(o.id) }).eq("id", pd.id);
    const pm = o.transactions?.payments?.[0]?.payment_method || {};
    if (!pm.qr_code) return json({ erro: "O Mercado Pago não devolveu o QR Code. Confira se o Pix está ativo na sua conta." }, 500);
    return json({ pedido: pd.id, qr: pm.qr_code, qr_base64: pm.qr_code_base64 });
  } catch (e) {
    console.error(e);
    return json({ erro: "Não deu para gerar o Pix agora. Tente de novo." }, 500);
  }
});
