// Servidor ao vivo da Cidade do Tonhão.
// Cada sala (1..60) é um Durable Object que recebe as conexões WebSocket dos jogadores
// e repassa posições ("pos"), avisos ("ev") e mensagens do chat ("chat") para os outros da sala.
// O login é conferido no Supabase (o jogador manda o token de acesso dele ao conectar).
// Mensagens que o servidor manda para os jogadores não são cobradas pelo Cloudflare.

const CORS = { 'Access-Control-Allow-Origin': '*' };

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    const m = url.pathname.match(/^\/sala\/(\d{1,2})$/);
    if (url.pathname === '/' ) return new Response('Cidade do Tonhão: servidor ao vivo OK', { headers: CORS });
    if (!m) return new Response('não encontrado', { status: 404, headers: CORS });
    const n = +m[1];
    if (n < 1 || n > 60) return new Response('sala inválida', { status: 400, headers: CORS });
    if (url.searchParams.get('contar') === '1') {
      const r = await env.SALA.get(env.SALA.idFromName('sala-' + n)).fetch(new Request('https://sala/contar'));
      return new Response(await r.text(), { headers: { ...CORS, 'Content-Type': 'application/json' } });
    }
    if (req.headers.get('Upgrade') !== 'websocket') return new Response('use WebSocket', { status: 426, headers: CORS });
    // confere o login no Supabase antes de deixar entrar (quem não está logado só assiste)
    let id = null;
    const token = url.searchParams.get('token');
    if (token) {
      try {
        const r = await fetch(env.SUPABASE_URL + '/auth/v1/user', { headers: { Authorization: 'Bearer ' + token, apikey: url.searchParams.get('k') || '' } });
        if (r.ok) { const u = await r.json(); if (u && u.id) id = u.id; }
      } catch (e) {}
      if (!id) return new Response('login inválido', { status: 401, headers: CORS });
    }
    const fwd = new Request('https://sala/ws?id=' + encodeURIComponent(id || '') + '&n=' + n + '&k=' + encodeURIComponent(url.searchParams.get('k') || ''), req);
    return env.SALA.get(env.SALA.idFromName('sala-' + n)).fetch(fwd);
  }
};

export class Sala {
  constructor(state, env) {
    this.state = state; this.env = env;
    // o "ping" do jogo é respondido sem acordar a sala (não cobra) e o horário fica guardado
    try { state.setWebSocketAutoResponse(new WebSocketRequestResponsePair('{"t":"ping"}', '{"t":"pong"}')); } catch (e) {}
  }

  // última vez que a conexão deu sinal de vida (entrou, mandou ping ou mandou algo)
  ultimoSinal(ws) {
    let t = 0;
    try { t = (ws.deserializeAttachment() || {}).ts || 0; } catch (e) {}
    try { const d = this.state.getWebSocketAutoResponseTimestamp(ws); if (d && +d > t) t = +d; } catch (e) {}
    return t;
  }

  abertas() { return this.state.getWebSockets().filter(ws => ws.readyState === 1); }

  // a cada 30 s: quem ficou mais de 75 s sem dar sinal (fechou o app, trocou de aba, perdeu o sinal) sai da sala
  async alarm() {
    const agora = Date.now();
    for (const ws of this.abertas()) {
      if (agora - this.ultimoSinal(ws) > 75000) { try { ws.close(4002, 'sem sinal'); } catch (e) {} this.saiu(ws); }
    }
    if (this.abertas().length) await this.state.storage.setAlarm(Date.now() + 30000);
  }

  async vigiar() {
    try { if (!(await this.state.storage.getAlarm())) await this.state.storage.setAlarm(Date.now() + 30000); } catch (e) {}
  }

  jogadores() { // conexões com login (quem só assiste não conta)
    return this.abertas().map(ws => { try { return ws.deserializeAttachment() || {}; } catch (e) { return {}; } }).filter(a => a.id);
  }

  async fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === '/contar') return new Response(JSON.stringify({ n: new Set(this.jogadores().map(a => a.id)).size }));
    const id = url.searchParams.get('id') || null;
    const max = +(this.env.MAX_SALA || 50);
    const ids = new Set(this.jogadores().map(a => a.id));
    const par = new WebSocketPair();
    const [cliente, servidor] = Object.values(par);
    if (id && !ids.has(id) && ids.size >= max) {
      this.state.acceptWebSocket(servidor);
      servidor.send(JSON.stringify({ t: 'cheia' }));
      servidor.close(4000, 'sala cheia');
      return new Response(null, { status: 101, webSocket: cliente });
    }
    // a mesma pessoa conectada de novo: fecha a conexão antiga
    if (id) for (const ws of this.state.getWebSockets()) { try { const a = ws.deserializeAttachment() || {}; if (a.id === id) ws.close(4001, 'conectou de novo'); } catch (e) {} }
    this.state.acceptWebSocket(servidor);
    servidor.serializeAttachment({ id, ts: Date.now(), k: url.searchParams.get('k') || '' });
    const lista = [...new Set(this.jogadores().map(a => a.id))];
    servidor.send(JSON.stringify({ t: 'oi', eu: id, ids: lista }));
    if (id) this.espalhar({ t: 'entrou', id }, servidor);
    await this.vigiar();
    return new Response(null, { status: 101, webSocket: cliente });
  }

  espalhar(obj, menos) {
    const txt = typeof obj === 'string' ? obj : JSON.stringify(obj);
    for (const ws of this.abertas()) { if (ws === menos) continue; try { ws.send(txt); } catch (e) {} }
  }

  async webSocketMessage(ws, msg) {
    if (typeof msg !== 'string' || msg.length > 4000) return;
    let a; try { a = ws.deserializeAttachment() || {}; } catch (e) { return; }
    if (!a.id) return; // quem só assiste não manda nada
    if (Date.now() - (a.ts || 0) > 20000) { a.ts = Date.now(); try { ws.serializeAttachment(a); } catch (e) {} }
    let d; try { d = JSON.parse(msg); } catch (e) { return; }
    if (!d || typeof d !== 'object') return;
    if (d.t === 'ping') { ws.send('{"t":"pong"}'); return; }
    if (d.t === 'pos' || d.t === 'ev') {
      const p = d.p && typeof d.p === 'object' ? d.p : {};
      p.i = a.id; // ninguém se passa por outro jogador
      this.espalhar({ t: d.t, p }, ws);
      return;
    }
    if (d.t === 'chat' && d.r && typeof d.r === 'object') {
      // só repassa mensagem que existe no banco (já passou pelo filtro e pelo silêncio) e que é dessa pessoa
      const cid = parseInt(d.r.id, 10);
      if (!(cid > 0) || !a.k) return;
      try {
        const res = await fetch(this.env.SUPABASE_URL + '/rest/v1/chat?id=eq.' + cid + '&select=id,sala,morador,nome,texto,criado_em', { headers: { apikey: a.k, Authorization: 'Bearer ' + a.k } });
        if (!res.ok) return;
        const rows = await res.json();
        const r = rows && rows[0];
        if (!r || r.morador !== a.id) return;
        this.espalhar({ t: 'chat', r }, ws);
      } catch (e) {}
    }
  }

  async webSocketClose(ws) { this.saiu(ws); }
  async webSocketError(ws) { this.saiu(ws); }
  saiu(ws) {
    let a; try { a = ws.deserializeAttachment() || {}; } catch (e) { a = {}; }
    if (!a.id || a.fora) return; // não avisa duas vezes
    try { a.fora = 1; ws.serializeAttachment(a); } catch (e) {}
    const ainda = this.abertas().some(o => { if (o === ws) return false; try { return (o.deserializeAttachment() || {}).id === a.id; } catch (e) { return false; } });
    if (!ainda) this.espalhar({ t: 'saiu', id: a.id }, ws);
  }
}
