-- banco- 3 de 16. Rode na ordem.
-- ---------- Segurança: todo mundo lê, ninguém escreve direto ----------
alter table public.moradores enable row level security;
alter table public.casas     enable row level security;
alter table public.trabalhos enable row level security;
alter table public.loja      enable row level security;
alter table public.vagas     enable row level security;
alter table public.frutas    enable row level security;
alter table public.chat      enable row level security;
alter table public.denuncias enable row level security;

drop policy if exists "ler moradores" on public.moradores;
create policy "ler moradores" on public.moradores for select using (true);
drop policy if exists "ler casas" on public.casas;
create policy "ler casas" on public.casas for select using (true);
drop policy if exists "ler trabalhos" on public.trabalhos;
create policy "ler trabalhos" on public.trabalhos for select using (true);
drop policy if exists "ler loja" on public.loja;
create policy "ler loja" on public.loja for select using (true);
drop policy if exists "ler vagas" on public.vagas;
create policy "ler vagas" on public.vagas for select using (true);
drop policy if exists "ler chat" on public.chat;
create policy "ler chat" on public.chat for select using (true);
-- frutas e denúncias: ninguém lê pelo app

-- Todas as escritas passam pelas funções abaixo, que conferem as regras.
revoke insert, update, delete on all tables in schema public from anon, authenticated;

-- ---------- Regras de nível ----------
-- Do nível N para o N+1 custa 50 × N de XP. XP total para chegar no nível N = 25 × N × (N − 1).
create or replace function public.xp_do_nivel(p_nivel integer) returns integer
language sql immutable as $$ select 25 * p_nivel * (p_nivel - 1) $$;

create or replace function public.nivel_de(p_xp integer) returns integer
language plpgsql immutable as $$
declare n integer := greatest(1, floor((1 + sqrt(1 + 4.0 * greatest(p_xp, 0) / 25)) / 2)::integer);
begin
  while public.xp_do_nivel(n + 1) <= p_xp loop n := n + 1; end loop;
  while n > 1 and public.xp_do_nivel(n) > p_xp loop n := n - 1; end loop;
  return least(n, 50);  -- nível máximo (aumente aqui no futuro)
end $$;

-- ---------- Funções internas ----------
create or replace function public._eu() returns public.moradores
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  if auth.uid() is null then raise exception 'Entre no jogo primeiro.'; end if;
  select * into m from moradores where id = auth.uid() for update;
  if not found then raise exception 'Crie seu morador primeiro.'; end if;
  if m.banido then raise exception 'Você foi banido da cidade.'; end if;
  return m;
end $$;

create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos)
  from moradores where id = p_id
$$;

-- Fome: cai 1 ponto a cada 2 minutos de jogo (no máximo 90 s contam entre duas ações,
-- então com o jogo fechado ela não cai) mais o custo do turno de trabalho.
-- Se chegar a zero: morre, perde 30% do XP do nível atual (sem cair de nível),
-- paga R$ 30 de hospital e volta com fome 50. Devolve true se morreu.
create or replace function public._gastar_fome(p_id uuid, p_custo numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare m public.moradores; f numeric; base integer;
begin
  select * into m from moradores where id = p_id for update;
  f := m.fome - least(extract(epoch from (now() - m.fome_em)), 90) / 120.0 - p_custo;
  if f <= 0 then
    base := xp_do_nivel(m.nivel);
    update moradores set fome = 50, fome_em = now(), visto_em = now(),
      xp = base + floor((m.xp - base) * 0.7), dinheiro = greatest(0, dinheiro - 30),
      mortes = mortes + 1, trabalho = null, trabalho_inicio = null
    where id = p_id;
    return true;
  end if;
  update moradores set fome = least(100, f), fome_em = now(), visto_em = now() where id = p_id;
  return false;
end $$;

-- ---------- Funções do jogo ----------
drop function if exists public.criar_morador(text, text);  -- a versão antiga devolvia outro formato
create or replace function public.criar_morador(p_nome text, p_visual text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; n text := btrim(regexp_replace(coalesce(p_nome,''), '\s+', ' ', 'g'));
begin
  if auth.uid() is null then raise exception 'Entre no jogo primeiro.'; end if;
  if char_length(n) < 1 or char_length(n) > 22 then raise exception 'O nome precisa ter de 1 a 22 letras.'; end if;
  if p_visual !~ '^TH[0-9]{7,30}$' then raise exception 'Visual inválido.'; end if;
  n := public.limpar_texto(n);
  insert into moradores(id, nome, visual) values (auth.uid(), n, upper(p_visual))
  on conflict (id) do update set nome = excluded.nome, visual = excluded.visual, visto_em = now(),
    fome_em = case when now() - moradores.visto_em > interval '2 minutes' then now() else moradores.fome_em end
    where not moradores.banido
  returning * into m;
  if m.id is null then raise exception 'Você foi banido da cidade.'; end if;
  return _estado(m.id);
end $$;

create or replace function public.pulso() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; morreu boolean; d numeric; tj integer; bonus integer := 0; novo_nivel integer; premio integer := 0;
begin
  m := _eu();
  -- tempo online: só conta até 90 s entre dois pulsos (jogo fechado não conta)
  d := least(coalesce(extract(epoch from (now() - m.tempo_em)), 0), 90);
  tj := m.tempo_jogo + d::integer;
  if tj >= 3600 then
    tj := tj - 3600; bonus := 50;
    novo_nivel := nivel_de(m.xp + bonus);
    if novo_nivel > m.nivel then
      select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
    else novo_nivel := m.nivel; end if;
  else novo_nivel := m.nivel; end if;
  update moradores set tempo_jogo = tj, tempo_em = now(), xp = xp + bonus, nivel = novo_nivel,
    dinheiro = dinheiro + premio where id = m.id;
  morreu := _gastar_fome(m.id, 0);
  return json_build_object('morreu', morreu, 'xp_hora', bonus, 'bonus_hora', bonus > 0, 'subiu', novo_nivel - m.nivel, 'premio', premio, 'eu', _estado(m.id));
end $$;

