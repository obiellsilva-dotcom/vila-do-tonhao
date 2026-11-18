-- etapas 31, 32 e 33: moderação, denúncias, feedback, jukebox das casas e móveis novos. Pode rodar de novo sem perder nada.

-- ===================== ETAPA 31: Moderação, denúncias e feedback =====================
-- Filtro: palavrão leve vira *** (como antes). Conteúdo GRAVE (sexual, assédio, pedofilia, estupro) é BLOQUEADO
-- e o jogador é silenciado na hora: 1ª vez 10 min, 2ª em 24 h = 1 hora, 3ª em diante = 24 horas (e vira denúncia automática).
-- Admin: silenciar/dessilenciar/banir pelo painel, ver denúncias (com as últimas mensagens do denunciado) e feedbacks.
alter table public.moradores add column if not exists silenciado_ate timestamptz;
alter table public.moradores add column if not exists strikes integer not null default 0;
alter table public.moradores add column if not exists strike_em timestamptz;
alter table public.denuncias add column if not exists contexto jsonb;
alter table public.denuncias add column if not exists resolvida boolean not null default false;
alter table public.denuncias add column if not exists auto boolean not null default false;

create table if not exists public.feedbacks (
  id        bigserial primary key,
  autor     uuid references public.moradores(id) on delete set null,
  nome      text,
  tipo      text not null default 'ideia',
  texto     text not null,
  lido      boolean not null default false,
  criado_em timestamptz not null default now()
);
alter table public.feedbacks enable row level security;

-- texto "normalizado": minúsculas, sem acento, números trocados por letras (c0m3r = comer), sem letras repetidas (cuuuu = cu)
create or replace function public._norm(t text) returns text
language sql immutable as $$
  select regexp_replace(regexp_replace(regexp_replace(
    translate(lower(coalesce(t, '')), 'áàâãäéèêëíìîïóòôõöúùûüç013457@$', 'aaaaaeeeeiiiiooooouuuucoieastas'),
    '[^a-z ]+', ' ', 'g'), '(.)\1+', '\1', 'g'), '\s+', ' ', 'g')
$$;

create or replace function public._grave(t text) returns boolean
language plpgsql immutable as $$
declare n text := ' ' || public._norm(t) || ' '; s text := replace(public._norm(t), ' ', '');
begin
  -- palavras inteiras (depois de normalizar: letras repetidas viram uma só)
  if n ~ '\m(cuzinho|cuzinhos|anus|anal|piroca|pirocao|xoxota|xota|xereca|punheta|siririca|boquete|putaria|nudes|nude|porno|pornografia|estupro|estupra|estuprar|estuprador|pedofilo|pedofilia|pedofila|transar|transa comigo|fazer sexo|faz sexo|sexo comigo)\M' then return true; end if;
  if n ~ '\m(come|comer|comia|chupa|chupar|mama|mamar|lambe|lamber|enfia|enfiar)\M( (o|a|seu|sua|teu|tua|meu|minha|esse|essa|no|na))? (cu|cuzinho|bunda|buceta|xota|xoxota|rola|pica|piroca|peito|peitos|anus)\M' then return true; end if;
  if n ~ '\m(quero|quer|qer|kero|qero|vou|vo) (te|ti) (comer|pegar|chupar|foder)\M' then return true; end if;
  if n ~ '\m(manda|mande|mostra|mostre) (foto|fotos|nude|nudes|os peitos|a bunda|a buceta|o pau)\M' then return true; end if;
  -- escrito com espaços ou pontos no meio (c u z i n h o)
  if s ~ '(cuzinho|pedofil|estupr|punheta|siririca|boquete|xoxota|piroca|putaria|pornografia|quertecomer|voutecomer|querocomerteu|querocomerseu)' then return true; end if;
  return false;
end $$;

-- confere a mensagem: silenciado não fala; grave = bloqueia, pune e cria denúncia automática. Devolve null se bloqueou.
create or replace function public._moderar(p_id uuid, t text) returns text
language plpgsql security definer set search_path = public as $$
declare m public.moradores; mins integer;
begin
  select * into m from moradores where id = p_id for update;
  if m.silenciado_ate is not null and m.silenciado_ate > now() then
    raise exception 'Você está silenciado até % por mensagens impróprias.', to_char(m.silenciado_ate at time zone 'America/Sao_Paulo', 'HH24:MI');
  end if;
  if not _grave(t) then return limpar_texto(t); end if;
  if m.strike_em is null or m.strike_em < now() - interval '24 hours' then m.strikes := 0; end if;
  m.strikes := m.strikes + 1;
  mins := case when m.strikes = 1 then 10 when m.strikes = 2 then 60 else 1440 end;
  update moradores set strikes = m.strikes, strike_em = now(), silenciado_ate = now() + make_interval(mins => mins) where id = p_id;
  insert into denuncias(autor, alvo, motivo, auto, contexto)
    values (p_id, p_id, '🤖 Filtro automático (' || m.strikes || 'ª vez em 24 h, silenciado ' || case when mins >= 1440 then '24 h' when mins >= 60 then '1 h' else mins || ' min' end || ')', true,
      jsonb_build_array(jsonb_build_object('texto', left(t, 300), 'em', now())));
  return null;
end $$;

create or replace function public.enviar_msg(p_sala integer, p_texto text) returns public.chat
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := btrim(regexp_replace(coalesce(p_texto,''), '\s+', ' ', 'g')); r public.chat; ok text;
begin
  m := _eu();
  if char_length(t) = 0 then raise exception 'Mensagem vazia.'; end if;
  t := left(t, 140);
  if m.ultima_msg is not null and now() - m.ultima_msg < interval '1.5 seconds' then
    raise exception 'Calma! Espere um pouquinho para mandar outra.';
  end if;
  if p_sala < 1 or p_sala > 100 then raise exception 'Sala inválida.'; end if;
  ok := _moderar(m.id, t);
  if ok is null then return null; end if; -- bloqueada (o jogador já ficou silenciado)
  update moradores set ultima_msg = now() where id = m.id;
  insert into chat(sala, morador, nome, texto) values (p_sala, m.id, m.nome, ok) returning * into r;
  return r;
end $$;

create or replace function public.enviar_dm(p_para uuid, p_texto text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := btrim(regexp_replace(coalesce(p_texto, ''), '\s+', ' ', 'g')); r public.mensagens; ok text;
begin
  m := _eu();
  if char_length(t) = 0 then raise exception 'Mensagem vazia.'; end if;
  t := left(t, 300);
  if not _sao_amigos(m.id, p_para) then raise exception 'Vocês precisam ser amigos para conversar.'; end if;
  if m.ultima_msg is not null and now() - m.ultima_msg < interval '1 second' then raise exception 'Calma! Espere um pouquinho para mandar outra.'; end if;
  ok := _moderar(m.id, t);
  if ok is null then return json_build_object('bloqueada', true); end if;
  update moradores set ultima_msg = now() where id = m.id;
  insert into mensagens(de, para, texto) values (m.id, p_para, ok) returning * into r;
  delete from mensagens where id in (
    select id from mensagens where least(de, para) = least(m.id, p_para) and greatest(de, para) = greatest(m.id, p_para)
    order by id desc offset 200);
  return json_build_object('id', r.id, 'de', r.de, 'para', r.para, 'texto', r.texto, 'criado_em', r.criado_em);
end $$;

-- denúncia guarda junto as últimas mensagens do denunciado (chat da cidade e conversa com quem denunciou)
create or replace function public.denunciar(p_alvo uuid, p_motivo text) returns void
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ctx jsonb;
begin
  m := _eu();
  if p_alvo = m.id then raise exception 'Não dá para se denunciar.'; end if;
  if (select count(*) from denuncias where autor = m.id and not auto and criado_em > now() - interval '1 hour') >= 10 then
    raise exception 'Muitas denúncias seguidas. Tente mais tarde.';
  end if;
  select coalesce(jsonb_agg(x order by x.em), '[]'::jsonb) into ctx from (
    (select texto, criado_em as em, 'chat' as onde from chat where morador = p_alvo order by id desc limit 10)
    union all
    (select texto, criado_em as em, 'privado' as onde from mensagens where de = p_alvo and para = m.id order by id desc limit 10)) x;
  insert into denuncias(autor, alvo, motivo, contexto) values (m.id, p_alvo, left(coalesce(p_motivo,''), 200), ctx);
end $$;

create or replace function public.enviar_feedback(p_tipo text, p_texto text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := btrim(coalesce(p_texto, ''));
begin
  m := _eu();
  if char_length(t) < 5 then raise exception 'Escreva um pouco mais (pelo menos 5 letras).'; end if;
  if (select count(*) from feedbacks where autor = m.id and criado_em > now() - interval '24 hours') >= 5 then
    raise exception 'Você já mandou 5 mensagens hoje. Obrigado! Tente amanhã.'; end if;
  insert into feedbacks(autor, nome, tipo, texto) values (m.id, m.nome,
    case when p_tipo in ('ideia','bug','elogio','outro') then p_tipo else 'outro' end, left(t, 1000));
  return json_build_object('ok', true);
end $$;

-- ---- admin ----
create or replace function public.admin_acao(p_nome text, p_acao text, p_valor text) returns json
language plpgsql security definer set search_path = public as $$
declare a public.moradores; n integer; c public.casas;
begin
  perform _adm();
  a := _alvo(p_nome);
  if p_acao = 'dinheiro' then
    n := p_valor::integer;
    update moradores set dinheiro = greatest(0, dinheiro + n) where id = a.id;
  elsif p_acao = 'vip' then
    n := greatest(1, p_valor::integer);
    update moradores set vip_ate = greatest(coalesce(vip_ate, now()), now()) + make_interval(days => n) where id = a.id;
  elsif p_acao = 'pet' then
    if p_valor not in ('cachorro','gato','galinha','capivara','papagaio') then raise exception 'Pet inválido.'; end if;
    update moradores set pets = (select array_agg(distinct x) from unnest(array_append(pets, p_valor)) x), pet = p_valor where id = a.id;
  elsif p_acao = 'carro' then
    update moradores set carros = (select array_agg(distinct x) from unnest(array_append(carros, p_valor)) x), carro = p_valor where id = a.id;
  elsif p_acao = 'casa' then
    select * into c from casas where id = p_valor::integer for update;
    if not found then raise exception 'Casa não existe.'; end if;
    update vagas set morador = null, carro = null, desde = null where casa in (select id from casas where dono = a.id);
    update casas set dono = null, comprada_em = null, aberta = false where dono = a.id;
    update casas set dono = a.id, comprada_em = now(), aberta = false where id = c.id;
    update moradores set casa_id = c.id where id = a.id;
  elsif p_acao = 'tirar_casa' then
    update casas set dono = null, comprada_em = null, aberta = false where dono = a.id;
    update moradores set casa_id = null where id = a.id;
  elsif p_acao = 'silenciar' then
    n := greatest(1, least(43200, coalesce(nullif(p_valor, '')::integer, 60)));
    update moradores set silenciado_ate = now() + make_interval(mins => n) where id = a.id;
  elsif p_acao = 'dessilenciar' then
    update moradores set silenciado_ate = null, strikes = 0 where id = a.id;
  elsif p_acao = 'banir' then
    update moradores set banido = true where id = a.id;
  elsif p_acao = 'desbanir' then
    update moradores set banido = false where id = a.id;
  else raise exception 'Ação desconhecida.'; end if;
  return json_build_object('ok', true, 'id', a.id, 'nome', a.nome);
end $$;

create or replace function public.admin_denuncias(p_todas boolean default false) returns json
language plpgsql security definer set search_path = public as $$
declare r json;
begin
  perform _adm();
  select coalesce(json_agg(x order by x.id desc), '[]'::json) into r from (
    select d.id, d.motivo, d.contexto, d.criado_em, d.resolvida, d.auto,
      au.nome as autor, al.id as alvo_id, al.nome as alvo, al.banido, al.silenciado_ate, al.strikes
    from denuncias d left join moradores au on au.id = d.autor left join moradores al on al.id = d.alvo
    where p_todas or not d.resolvida order by d.id desc limit 60) x;
  return r;
end $$;

create or replace function public.admin_feedbacks() returns json
language plpgsql security definer set search_path = public as $$
declare r json;
begin
  perform _adm();
  select coalesce(json_agg(x order by x.id desc), '[]'::json) into r from (
    select id, nome, tipo, texto, lido, criado_em from feedbacks order by id desc limit 80) x;
  return r;
end $$;

create or replace function public.admin_resolver(p_tipo text, p_id bigint) returns json
language plpgsql security definer set search_path = public as $$
begin
  perform _adm();
  if p_tipo = 'denuncia' then update denuncias set resolvida = true where id = p_id;
  elsif p_tipo = 'feedback' then update feedbacks set lido = true where id = p_id;
  else raise exception 'Tipo inválido.'; end if;
  return json_build_object('ok', true);
end $$;

create or replace function public.admin_contagem() returns json
language plpgsql security definer set search_path = public as $$
begin
  perform _adm();
  return json_build_object('denuncias', (select count(*) from denuncias where not resolvida),
                           'feedbacks', (select count(*) from feedbacks where not lido));
end $$;

revoke execute on function public._norm(text), public._grave(text), public._moderar(uuid, text) from public, anon, authenticated;
revoke execute on function public.enviar_feedback(text, text), public.admin_denuncias(boolean), public.admin_feedbacks(),
  public.admin_resolver(text, bigint), public.admin_contagem() from public, anon;
grant execute on function public.enviar_msg(integer, text), public.enviar_dm(uuid, text), public.denunciar(uuid, text), public.enviar_feedback(text, text),
  public.admin_acao(text, text, text), public.admin_denuncias(boolean), public.admin_feedbacks(), public.admin_resolver(text, bigint), public.admin_contagem() to authenticated;

-- ===================== ETAPA 32: Jukebox das casas =====================
-- O dono escolhe a música e ela fica tocando na casa (quem entra depois ouve do mesmo ponto).
alter table public.casas add column if not exists juke jsonb;

create or replace function public.tocar_jukebox(p_casa integer, p_faixa text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; j jsonb;
begin
  m := _eu();
  select * into c from casas where id = p_casa;
  if not found then raise exception 'Casa não existe.'; end if;
  if c.dono is distinct from m.id then raise exception 'Só o dono da casa escolhe a música.'; end if;
  if p_faixa is null or p_faixa = '' then j := null;
  else
    if p_faixa !~ '^[a-z0-9-]{2,40}$' then raise exception 'Música inválida.'; end if;
    j := jsonb_build_object('f', p_faixa, 'em', now());
  end if;
  update casas set juke = j where id = p_casa;
  return json_build_object('juke', j);
end $$;
revoke execute on function public.tocar_jukebox(integer, text) from public, anon;
grant execute on function public.tocar_jukebox(integer, text) to authenticated;

-- ===================== ETAPA 33: Móveis novos (banheiro, cozinha, lazer, quarto, decoração, luxo, VIP e com efeito) =====================
create or replace function public.preco_movel(p_tipo text) returns integer
language sql immutable as $$
  select case p_tipo
    when 'parede' then 200 when 'porta' then 600
    when 'caixote' then 80 when 'cadeira' then 150 when 'planta' then 250 when 'colchao' then 300
    when 'tapete' then 400 when 'abajur' then 350 when 'criado' then 450 when 'mesinha' then 500
    when 'mesa' then 900 when 'pia' then 1100 when 'estante' then 1200 when 'fogao' then 1300
    when 'poltrona' then 1400 when 'armario' then 1600 when 'geladeira' then 1800 when 'sofa' then 2200
    when 'tv' then 2500 when 'cama' then 3000 when 'somcx' then 3000 when 'led' then 2000
    when 'aquario' then 6000 when 'homet' then 9000 when 'jukebox' then 12000
    when 'vaso' then 700 when 'piabanho' then 900 when 'chuveiro' then 1500 when 'banheira' then 3200 when 'toalheiro' then 400 when 'armpar' then 1100 when 'micro' then 1300 when 'cafeteira' then 800 when 'balcao' then 2600 when 'churras' then 3500 when 'rede' then 900 when 'cadpraia' then 450 when 'piscina' then 1800 when 'gamer' then 4500 when 'cadgamer' then 2200 when 'sofacurvo' then 4800 when 'sofamod' then 5600 when 'painel' then 2400 when 'mesaredonda' then 1300 when 'leitura' then 2000 when 'camaking' then 6500 when 'beliche' then 2400 when 'penteadeira' then 2100 when 'comoda' then 1500 when 'quadro' then 600 when 'quadro2' then 900 when 'espelho' then 1100 when 'taprd' then 700 when 'cortina' then 800 when 'lumichao' then 900 when 'relogio' then 500 when 'plantag' then 700 when 'trofeu' then 1500 when 'lustre' then 18000 when 'piano' then 28000 when 'estatua' then 15000 when 'sofacouro' then 12000 when 'adega' then 9500 when 'vitrola' then 7500 when 'trono' then 20000 when 'hidro' then 24000 when 'massag' then 16000 when 'arcade' then 14000 when 'aqparede' then 22000 when 'lareira' then 8000 when 'globo' then 6000 when 'neon' then 5000 when 'neon2' then 3500 when 'fonte' then 9000 when 'lava' then 2500 else null end
$$;

-- móveis só para VIP
create or replace function public.movel_vip(p_tipo text) returns boolean
language sql immutable as $$ select p_tipo in ('trono','hidro','massag','arcade','aqparede') $$;

create or replace function public.comprar_movel(p_casa integer, p_tipo text, p_x integer, p_y integer, p_andar integer, p_r integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pr integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  pr := preco_movel(p_tipo);
  if pr is null then raise exception 'Móvel inválido.'; end if;
  if movel_vip(p_tipo) and not (m.vip_ate is not null and m.vip_ate > now()) then raise exception 'Esse móvel é só para VIP.'; end if;
  if p_x < 0 or p_x > 30 or p_y < 0 or p_y > 30 or p_andar not in (0, 1) or p_r not between 0 and 3 then raise exception 'Lugar inválido.'; end if;
  if jsonb_array_length(c.moveis) >= 80 then raise exception 'Sua casa já tem móveis demais (máximo 80).'; end if;
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', pr; end if;
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  update casas set moveis = moveis || jsonb_build_array(jsonb_build_object('t', p_tipo, 'x', p_x, 'y', p_y, 'a', p_andar, 'r', p_r)) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;
-- ===================== ETAPA 35: Carros novos (Pantera GT e Rolezinho) e nomes sem marca =====================
-- Pantera GT entra no lugar do Fusca Dourado (mesmo preço da Rosso GT). Rolezinho entra no lugar da Kombi.
-- Brutona (antiga Amarok) passa a custar 123 mil. Nomes trocados para não usar marcas registradas.
update public.loja set nome = 'Besouro'       where id = 'fusca'       and tipo = 'carro';
update public.loja set nome = 'Rolezinho'     where id = 'kombi'       and tipo = 'carro';
update public.loja set nome = 'Clássico 79'   where id = 'opala'       and tipo = 'carro';
update public.loja set nome = 'Brutona', preco = 123000 where id = 'caminhonete' and tipo = 'carro';
update public.loja set nome = 'Jipe Aventura' where id = 'jipe'        and tipo = 'carro';
update public.loja set nome = 'Explorador'    where id = 'esportivo'   and tipo = 'carro';
update public.produtos set nome = 'Pantera GT', preco = 19.90 where id = 'carro_fusca_ouro';
update public.produtos set nome = 'Rosso GT'    where id = 'carro_gto';
update public.produtos set nome = 'Lâmina V12'  where id = 'carro_neon';
