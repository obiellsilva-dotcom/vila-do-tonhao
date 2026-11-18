-- etapa 30: celular (amigos, mensagens privadas, banco e investimento). Pode rodar de novo sem perder nada.

-- ===================== ETAPA 30: Celular (amigos, mensagens privadas, banco e investimento) =====================
-- Amizade: um pede, o outro aceita. Mensagens privadas só entre amigos (menos spam e mais segurança).
-- Investimento: rende 1% ao dia (juros simples por dia, somados ao saldo investido), base máxima R$ 100 mil
-- (no máximo R$ 1.000 por dia); cada depósito prende o dinheiro por 24 h.
create table if not exists public.amizades (
  de        uuid not null references public.moradores(id) on delete cascade,
  para      uuid not null references public.moradores(id) on delete cascade,
  aceita    boolean not null default false,
  criado_em timestamptz not null default now(),
  primary key (de, para),
  check (de <> para)
);
create index if not exists amizades_para on public.amizades(para);
alter table public.amizades enable row level security;

create table if not exists public.mensagens (
  id        bigserial primary key,
  de        uuid not null references public.moradores(id) on delete cascade,
  para      uuid not null references public.moradores(id) on delete cascade,
  texto     text not null,
  lida      boolean not null default false,
  criado_em timestamptz not null default now()
);
create index if not exists mensagens_par on public.mensagens (least(de, para), greatest(de, para), id desc);
create index if not exists mensagens_naolidas on public.mensagens (para) where not lida;
alter table public.mensagens enable row level security;

alter table public.moradores add column if not exists invest_valor    integer not null default 0;
alter table public.moradores add column if not exists invest_em       timestamptz;
alter table public.moradores add column if not exists invest_bloq_ate timestamptz;
alter table public.moradores add column if not exists invest_ganho    integer not null default 0;

create or replace function public._sao_amigos(a uuid, b uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from amizades where aceita and ((de = a and para = b) or (de = b and para = a)))
$$;

create or replace function public.pedir_amizade(p_id uuid) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_id = m.id then raise exception 'Você não pode adicionar você mesmo.'; end if;
  if not exists (select 1 from moradores where id = p_id and not banido) then raise exception 'Morador não encontrado.'; end if;
  if _sao_amigos(m.id, p_id) then return json_build_object('amigos', true); end if;
  -- se a outra pessoa já tinha pedido, vira amizade na hora
  if exists (select 1 from amizades where de = p_id and para = m.id) then
    update amizades set aceita = true where de = p_id and para = m.id;
    return json_build_object('amigos', true);
  end if;
  if (select count(*) from amizades where de = m.id and not aceita) >= 30 then raise exception 'Você já tem 30 pedidos esperando resposta.'; end if;
  if (select count(*) from amizades where aceita and (de = m.id or para = m.id)) >= 200 then raise exception 'Limite de 200 amigos.'; end if;
  insert into amizades(de, para) values (m.id, p_id) on conflict do nothing;
  return json_build_object('pedido', true);
end $$;

create or replace function public.responder_amizade(p_id uuid, p_aceitar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_aceitar then update amizades set aceita = true where de = p_id and para = m.id;
  else delete from amizades where de = p_id and para = m.id and not aceita; end if;
  return json_build_object('ok', true);
end $$;

create or replace function public.desfazer_amizade(p_id uuid) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  delete from amizades where (de = m.id and para = p_id) or (de = p_id and para = m.id);
  return json_build_object('ok', true);
end $$;

create or replace function public.meus_amigos() returns json
language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); r json;
begin
  if u is null then raise exception 'Entre no jogo primeiro.'; end if;
  select coalesce(json_agg(x order by x.online desc, x.nome), '[]'::json) into r from (
    select o.id, o.nome, o.nivel, o.foto, o.visual, o.vip_ate,
      (o.visto_em > now() - interval '150 seconds') as online,
      case when a.aceita then 'amigo' when a.de = u then 'enviado' else 'recebido' end as status
    from amizades a join moradores o on o.id = case when a.de = u then a.para else a.de end
    where (a.de = u or a.para = u) and not o.banido) x;
  return r;
end $$;

create or replace function public.buscar_moradores(p_nome text) returns json
language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); t text := btrim(coalesce(p_nome, '')); r json;
begin
  if u is null then raise exception 'Entre no jogo primeiro.'; end if;
  if char_length(t) < 2 then return '[]'::json; end if;
  t := replace(replace(replace(left(t, 22), '\', ''), '%', ''), '_', '');
  select coalesce(json_agg(x), '[]'::json) into r from (
    select id, nome, nivel, foto, visual, vip_ate from moradores
    where nome ilike t || '%' and id <> u and not banido
    order by visto_em desc limit 20) x;
  return r;
end $$;

create or replace function public.enviar_dm(p_para uuid, p_texto text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := btrim(regexp_replace(coalesce(p_texto, ''), '\s+', ' ', 'g')); r public.mensagens;
begin
  m := _eu();
  if char_length(t) = 0 then raise exception 'Mensagem vazia.'; end if;
  t := left(t, 300);
  if not _sao_amigos(m.id, p_para) then raise exception 'Vocês precisam ser amigos para conversar.'; end if;
  if m.ultima_msg is not null and now() - m.ultima_msg < interval '1 second' then raise exception 'Calma! Espere um pouquinho para mandar outra.'; end if;
  update moradores set ultima_msg = now() where id = m.id;
  insert into mensagens(de, para, texto) values (m.id, p_para, limpar_texto(t)) returning * into r;
  -- guarda só as 200 últimas de cada conversa
  delete from mensagens where id in (
    select id from mensagens where least(de, para) = least(m.id, p_para) and greatest(de, para) = greatest(m.id, p_para)
    order by id desc offset 200);
  return json_build_object('id', r.id, 'de', r.de, 'para', r.para, 'texto', r.texto, 'criado_em', r.criado_em);
end $$;

create or replace function public.conversas() returns json
language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); r json;
begin
  if u is null then raise exception 'Entre no jogo primeiro.'; end if;
  select coalesce(json_agg(x order by x.ultima_id desc nulls last, x.nome), '[]'::json) into r from (
    select o.id, o.nome, o.foto, o.visual, o.vip_ate, (o.visto_em > now() - interval '150 seconds') as online,
      l.id as ultima_id, l.texto as ultima, l.de as ultima_de, l.criado_em as ultima_em,
      (select count(*) from mensagens n where n.de = o.id and n.para = u and not n.lida) as naolidas
    from amizades a join moradores o on o.id = case when a.de = u then a.para else a.de end
    left join lateral (select id, texto, de, criado_em from mensagens mm
      where least(mm.de, mm.para) = least(u, o.id) and greatest(mm.de, mm.para) = greatest(u, o.id)
      order by id desc limit 1) l on true
    where a.aceita and (a.de = u or a.para = u) and not o.banido) x;
  return r;
end $$;

create or replace function public.conversa(p_com uuid, p_antes bigint default null) returns json
language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); r json;
begin
  if u is null then raise exception 'Entre no jogo primeiro.'; end if;
  update mensagens set lida = true where de = p_com and para = u and not lida;
  select coalesce(json_agg(x order by x.id), '[]'::json) into r from (
    select id, de, texto, criado_em from mensagens
    where least(de, para) = least(u, p_com) and greatest(de, para) = greatest(u, p_com) and (p_antes is null or id < p_antes)
    order by id desc limit 50) x;
  return r;
end $$;

create or replace function public.nao_lidas() returns json
language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid(); r json;
begin
  if u is null then return json_build_object('msgs', 0, 'pedidos', 0); end if;
  select json_build_object(
    'msgs', (select count(*) from mensagens where para = u and not lida),
    'pedidos', (select count(*) from amizades where para = u and not aceita),
    'ultima_id', (select max(id) from mensagens where para = u and not lida),
    'ultima_de', (select o.nome from mensagens mm join moradores o on o.id = mm.de where mm.para = u and not mm.lida order by mm.id desc limit 1)) into r;
  return r;
end $$;

-- rendimento: soma o que rendeu desde a última conta (1% ao dia sobre no máximo R$ 100 mil)
create or replace function public._render(p_id uuid) returns void
language plpgsql security definer set search_path = public as $$
declare v integer; e timestamptz; base numeric; g integer;
begin
  select invest_valor, invest_em into v, e from moradores where id = p_id for update;
  if v is null or v <= 0 or e is null then return; end if;
  base := least(v, 100000) * 0.01;
  g := floor(base * extract(epoch from (now() - e)) / 86400.0);
  if g >= 1 then
    update moradores set invest_valor = invest_valor + g, invest_ganho = invest_ganho + g,
      invest_em = invest_em + make_interval(secs => g / base * 86400.0) where id = p_id;
  end if;
end $$;

create or replace function public._banco(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('saldo', dinheiro, 'investido', invest_valor, 'ganho', invest_ganho,
    'por_dia', floor(least(invest_valor, 100000) * 0.01), 'bloq_ate', invest_bloq_ate, 'limite', 100000, 'taxa', 1)
  from moradores where id = p_id
$$;

create or replace function public.banco_info() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  perform _render(m.id);
  return _banco(m.id);
end $$;

create or replace function public.investir(p_valor integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  perform _render(m.id);
  select * into m from moradores where id = m.id;
  if p_valor is null or p_valor < 1 then raise exception 'Valor inválido.'; end if;
  if p_valor > m.dinheiro then raise exception 'Você não tem esse dinheiro na carteira.'; end if;
  if m.invest_valor + p_valor > 100000 then raise exception 'O limite do investimento é R$ 100.000.'; end if;
  update moradores set dinheiro = dinheiro - p_valor, invest_valor = invest_valor + p_valor,
    invest_em = case when invest_valor > 0 and invest_em is not null then invest_em else now() end,
    invest_bloq_ate = now() + interval '24 hours' where id = m.id;
  return json_build_object('banco', _banco(m.id), 'eu', _estado(m.id));
end $$;

create or replace function public.resgatar(p_valor integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  perform _render(m.id);
  select * into m from moradores where id = m.id;
  if p_valor is null or p_valor < 1 then raise exception 'Valor inválido.'; end if;
  if m.invest_bloq_ate is not null and now() < m.invest_bloq_ate then
    raise exception 'O dinheiro fica guardado 24 horas depois de cada depósito. Tente de novo mais tarde.'; end if;
  if p_valor > m.invest_valor then raise exception 'Você não tem tudo isso investido.'; end if;
  update moradores set dinheiro = dinheiro + p_valor, invest_valor = invest_valor - p_valor,
    invest_em = case when invest_valor - p_valor > 0 then invest_em else null end where id = m.id;
  return json_build_object('banco', _banco(m.id), 'eu', _estado(m.id));
end $$;

revoke execute on function public._sao_amigos(uuid, uuid), public._render(uuid), public._banco(uuid) from public, anon, authenticated;
revoke execute on function public.pedir_amizade(uuid), public.responder_amizade(uuid, boolean), public.desfazer_amizade(uuid), public.meus_amigos(),
  public.buscar_moradores(text), public.enviar_dm(uuid, text), public.conversas(), public.conversa(uuid, bigint), public.nao_lidas(),
  public.banco_info(), public.investir(integer), public.resgatar(integer) from public, anon;
grant execute on function public.pedir_amizade(uuid), public.responder_amizade(uuid, boolean), public.desfazer_amizade(uuid), public.meus_amigos(),
  public.buscar_moradores(text), public.enviar_dm(uuid, text), public.conversas(), public.conversa(uuid, bigint), public.nao_lidas(),
  public.banco_info(), public.investir(integer), public.resgatar(integer) to authenticated;
