-- Banco completo, parte 1 de 4. Rode na ordem (1, 2, 3, 4).
-- =====================================================================
--  Cidade do Tonhão: banco de dados do jogo online (Supabase)
--  Cole este arquivo inteiro no Supabase: SQL Editor > New query > Run.
--  Pode rodar de novo sem problema: ele cria o que falta e atualiza
--  preços, salários e níveis.
-- =====================================================================

-- ---------- Tabelas ----------
create table if not exists public.moradores (
  id               uuid primary key references auth.users(id) on delete cascade,
  nome             text not null check (char_length(nome) between 1 and 22),
  visual           text not null check (visual ~ '^TH[0-9]{7}$'),
  dinheiro         integer not null default 100 check (dinheiro >= 0),
  carros           text[] not null default '{}',
  carro            text,
  casa_id          integer,
  trabalho         text,
  trabalho_inicio  timestamptz,
  turnos           integer not null default 0,
  banido           boolean not null default false,
  ultima_msg       timestamptz,
  criado_em        timestamptz not null default now()
);
alter table public.moradores add column if not exists xp        integer not null default 0;
alter table public.moradores add column if not exists nivel     integer not null default 1;
alter table public.moradores add column if not exists fome      numeric not null default 100;
alter table public.moradores add column if not exists fome_em   timestamptz not null default now();
alter table public.moradores add column if not exists peixes    integer not null default 0;
alter table public.moradores add column if not exists mortes    integer not null default 0;
alter table public.moradores add column if not exists visto_em  timestamptz not null default now();
alter table public.moradores add column if not exists foto           text;
alter table public.moradores add column if not exists frase          text;
alter table public.moradores add column if not exists relacionamento text;
alter table public.moradores add column if not exists time_coracao   text;
alter table public.moradores add column if not exists insta          text;
alter table public.moradores add column if not exists sinuca_em      timestamptz;
alter table public.moradores add column if not exists tempo_jogo     integer not null default 0;  -- segundos online desde o último bônus
alter table public.moradores add column if not exists tempo_em       timestamptz;
alter table public.moradores add column if not exists vip_ate        timestamptz;
alter table public.moradores add column if not exists pets           text[] not null default '{}';
alter table public.moradores add column if not exists pet            text;
-- o visual ganhou roupas e calçados: o código agora pode ter até 12 dígitos
alter table public.moradores drop constraint if exists moradores_visual_check;
alter table public.moradores add constraint moradores_visual_check check (visual ~ '^(TH[0-9]{7,30}|TJ[0-9]{20,30})$') not valid;
create index if not exists moradores_ranking on public.moradores(xp desc) where not banido;

create table if not exists public.casas (
  id           integer primary key,
  preco        integer not null check (preco > 0),
  dono         uuid references public.moradores(id) on delete set null,
  comprada_em  timestamptz
);
alter table public.casas add column if not exists nivel_min integer not null default 1;
alter table public.casas add column if not exists aberta boolean not null default false;
-- cada jogador pode ter no máximo 1 casa de cada tipo (barata, intermediária, mansão)
alter table public.casas add column if not exists tipo text generated always as (case when preco >= 50000 then 'mansao' when preco >= 10000 then 'media' else 'barata' end) stored;
drop index if exists public.casas_um_dono;
create unique index if not exists casas_um_por_tipo on public.casas(dono, tipo) where dono is not null;

create table if not exists public.trabalhos (
  id       text primary key,
  nome     text not null,
  salario  integer not null check (salario >= 0),
  duracao  integer not null check (duracao > 0)   -- segundos de turno
);
alter table public.trabalhos add column if not exists nivel_min integer not null default 1;
alter table public.trabalhos add column if not exists xp        integer not null default 10;
alter table public.trabalhos add column if not exists fome      integer not null default 8;   -- fome gasta por turno
alter table public.trabalhos drop constraint if exists trabalhos_salario_check;
alter table public.trabalhos add constraint trabalhos_salario_check check (salario >= 0);

create table if not exists public.loja (
  id     text primary key,
  tipo   text not null,
  nome   text not null,
  preco  integer not null check (preco > 0)
);
alter table public.loja add column if not exists local     text not null default 'bar';
alter table public.loja add column if not exists fome      integer not null default 0;   -- quanto mata a fome
alter table public.loja add column if not exists nivel_min integer not null default 1;
alter table public.loja drop constraint if exists loja_tipo_check;
update public.loja set tipo = 'consumo' where tipo = 'bar';
alter table public.loja add constraint loja_tipo_check check (tipo in ('consumo','carro'));

create table if not exists public.vagas (
  id       text primary key,
  casa     integer,                 -- se tiver número, é a garagem dessa casa
  morador  uuid unique references public.moradores(id) on delete set null,
  carro    text,
  desde    timestamptz
);

create table if not exists public.frutas (
  morador  uuid not null references public.moradores(id) on delete cascade,
  arvore   integer not null,
  quando   timestamptz not null default now(),
  primary key (morador, arvore)
);

create table if not exists public.chat (
  id         bigserial primary key,
  sala       integer not null,
  morador    uuid not null references public.moradores(id) on delete cascade,
  nome       text not null,
  texto      text not null check (char_length(texto) between 1 and 140),
  criado_em  timestamptz not null default now()
);
create index if not exists chat_sala_id on public.chat(sala, id desc);

create table if not exists public.denuncias (
  id         bigserial primary key,
  autor      uuid not null references public.moradores(id) on delete cascade,
  alvo       uuid not null references public.moradores(id) on delete cascade,
  motivo     text,
  criado_em  timestamptz not null default now()
);

-- ---------- Catálogo (preços, salários e níveis ficam AQUI, no servidor) ----------
insert into public.trabalhos(id, nome, salario, duracao, nivel_min, xp, fome) values
  ('bar',            'Garçom do Tonhão',     45, 40,  1, 15,  8),
  ('mercadinho',     'Repositor',            50, 45,  1, 18,  9),
  ('posto',          'Frentista',            50, 40,  2, 18,  8),
  ('padaria',        'Padeiro',              55, 50,  3, 21,  9),
  ('pescador',       'Pescador',              0, 45,  3, 18,  8),
  ('barbearia',      'Barbeiro',             60, 50,  4, 22, 10),
  ('prefeitura',     'Servidor público',     70, 60,  5, 27, 10),
  ('oficina',        'Mecânico',             80, 60,  6, 30, 12),
  ('policia',        'Policial',             95, 60, 15, 33, 12),
  ('banco',          'Caixa do banco',       90, 75,  8, 38, 12),
  ('concessionaria', 'Vendedor de carros',  100, 90, 10, 45, 14),
  ('fabrica',        'Operário da fábrica', 110, 90, 12, 48, 15)
on conflict (id) do update set nome = excluded.nome, salario = excluded.salario, duracao = excluded.duracao,
  nivel_min = excluded.nivel_min, xp = excluded.xp, fome = excluded.fome;

insert into public.loja(id, tipo, nome, preco, local, fome, nivel_min) values
  ('cerveja',     'consumo', 'uma cerveja',                 8, 'bar',         0, 1),
  ('pinga',       'consumo', 'uma pinga',                   4, 'bar',         0, 1),
  ('guarana',     'consumo', 'um guaraná',                  6, 'bar',         2, 1),
  ('pastel',      'consumo', 'um pastel',                   6, 'bar',        15, 1),
  ('pf',          'consumo', 'um prato feito',             18, 'bar',        50, 1),
  ('porcao',      'consumo', 'uma porção de batata',       25, 'bar',        35, 1),
  ('rodada',      'consumo', 'uma rodada pra todo mundo',  80, 'bar',         0, 1),
  ('cafe',        'consumo', 'um cafezinho',                3, 'padaria',     3, 1),
  ('pao',         'consumo', 'um pão na chapa',             5, 'padaria',    15, 1),
  ('coxinha',     'consumo', 'uma coxinha',                 7, 'padaria',    20, 1),
  ('cesta',       'consumo', 'uma cesta básica',           60, 'mercadinho', 100, 1),
  ('moto',        'carro',   'Motoca',                   1800, 'carros',      0, 1),
  ('fusca',       'carro',   'Fusca',                    3000, 'carros',      0, 1),
  ('kombi',       'carro',   'Kombi',                    5500, 'carros',      0, 3),
  ('opala',       'carro',   'Opala',                   12000, 'carros',      0, 6),
  ('caminhonete', 'carro',   'Caminhonete',             25000, 'carros',      0, 10)
on conflict (id) do update set tipo = excluded.tipo, nome = excluded.nome, preco = excluded.preco,
  local = excluded.local, fome = excluded.fome, nivel_min = excluded.nivel_min;
delete from public.loja where id = 'bar';

-- casas: os números batem com as plaquinhas do mapa (gerado a partir do mapa; não edite os ids)
insert into public.casas(id,preco,nivel_min) values
(1,12000,1),
(2,12000,1),
(3,12000,1),
(4,12000,1),
(5,12000,1),
(6,12000,1),
(7,12000,1),
(8,12000,1),
(9,12000,1),
(10,12000,1),
(11,12000,1),
(12,12000,1),
(13,12000,1),
(14,12000,1),
(15,12000,1),
(16,12000,1),
(17,12000,1),
(18,12000,1),
(19,12000,1),
(20,12000,1),
(21,12000,1),
(22,12000,1),
(23,12000,1),
(24,12000,1),
(25,12000,1),
(26,12000,1),
(27,12000,1),
(28,12000,1),
(29,12000,1),
(30,12000,1),
(31,12000,1),
(32,12000,1),
(33,12000,1),
(34,12000,1),
(35,12000,1),
(36,12000,1),
(37,12000,1),
(38,12000,1),
(39,12000,1),
(40,12000,1),
(41,12000,1),
(42,12000,1),
(43,12000,1),
(44,12000,1),
(45,12000,1),
(46,12000,1),
(47,12000,1),
(48,12000,1),
(49,12000,1),
(50,12000,1),
(51,12000,1),
(52,12000,1),
(53,20000,1),
(54,20000,1),
(55,20000,1),
(56,20000,1),
(57,20000,1),
(58,20000,1),
(59,20000,1),
(60,20000,1),
(61,20000,1),
(62,20000,1),
(63,20000,1),
(64,20000,1),
(65,20000,1),
(66,20000,1),
(67,20000,1),
(68,90000,10),
(69,90000,10),
(70,90000,10),
(71,90000,10),
(72,90000,10),
(73,90000,10),
(74,90000,10),
(75,90000,10),
(76,90000,10),
(77,90000,10),
(78,8000,1),
(79,8000,1),
(80,8000,1),
(81,8000,1),
(82,8000,1),
(83,8000,1),
(84,8000,1),
(85,8000,1),
(86,8000,1),
(87,8000,1),
(88,8000,1),
(89,8000,1),
(90,8000,1),
(91,8000,1),
(92,8000,1),
(93,8000,1),
(94,8000,1),
(95,8000,1),
(96,8000,1),
(97,8000,1),
(98,8000,1),
(99,8000,1),
(100,8000,1),
(101,8000,1),
(102,8000,1),
(103,8000,1),
(104,8000,1),
(105,8000,1),
(106,8000,1),
(107,8000,1),
(108,8000,1),
(109,8000,1)
on conflict (id) do update set preco=excluded.preco, nivel_min=excluded.nivel_min;

-- vagas de estacionamento (geradas a partir do mapa; não edite os ids)
insert into public.vagas(id,casa) values
('v0',null),
('v1',null),
('v2',null),
('v3',null),
('v4',null),
('v5',null),
('v6',null),
('v7',null),
('v8',null),
('v9',null),
('v10',null),
('v11',null),
('v12',null),
('v13',null),
('v14',null),
('v15',null),
('v16',null),
('v17',null),
('v18',null),
('v19',null),
('v20',null),
('v21',null),
('v22',null),
('v23',null),
('v24',null),
('v25',null),
('v26',null),
('v27',null),
('v28',null),
('v29',null),
('v30',null),
('v31',null),
('v32',null),
('v33',null),
('v34',null),
('v35',null),
('v36',null),
('v37',null),
('v38',null),
('v39',null),
('v40',null),
('v41',null),
('v42',null),
('v43',null),
('v44',null),
('v45',null),
('v46',null),
('v47',null),
('v48',null),
('v49',null),
('g1',1),
('g2',2),
('g3',3),
('g4',4),
('g5',5),
('g6',6),
('g7',7),
('g8',8),
('g9',9),
('g10',10),
('g11',11),
('g12',12),
('g13',13),
('g14',14),
('g15',15),
('g16',16),
('g17',17),
('g18',18),
('g19',19),
('g20',20),
('g21',21),
('g22',22),
('g23',23),
('g24',24),
('g25',25),
('g26',26),
('g27',27),
('g28',28),
('g29',29),
('g30',30),
('g31',31),
('g32',32),
('g33',33),
('g34',34),
('g35',35),
('g36',36),
('g37',37),
('g38',38),
('g39',39),
('g40',40),
('g41',41),
('g42',42),
('g43',43),
('g44',44),
('g45',45),
('g46',46),
('g47',47),
('g48',48),
('g49',49),
('g50',50),
('g51',51),
('g52',52),
('g53',53),
('g54',54),
('g55',55),
('g56',56),
('g57',57),
('g58',58),
('g59',59),
('g60',60),
('g61',61),
('g62',62),
('g63',63),
('g64',64),
('g65',65),
('g66',66),
('g67',67),
('g68',68),
('g69',69),
('g70',70),
('g71',71),
('g72',72),
('g73',73),
('g74',74),
('g75',75),
('g76',76),
('g77',77),
('g78',78),
('g79',79),
('g80',80),
('g81',81),
('g82',82),
('g83',83),
('g84',84),
('g85',85),
('g86',86),
('g87',87),
('g88',88),
('g89',89),
('g90',90),
('g91',91),
('g92',92),
('g93',93),
('g94',94),
('g95',95),
('g96',96),
('g97',97),
('g98',98),
('g99',99),
('g100',100),
('g101',101),
('g102',102),
('g103',103),
('g104',104),
('g105',105),
('g106',106),
('g107',107),
('g108',108),
('g109',109)
on conflict (id) do update set casa=excluded.casa;

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

create or replace function public.comecar_trabalho(p_trabalho text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; morreu boolean;
begin
  m := _eu();
  select * into t from trabalhos where id = p_trabalho;
  if not found then raise exception 'Esse trabalho não existe.'; end if;
  if m.nivel < t.nivel_min then raise exception 'Esse trabalho libera no nível %.', t.nivel_min; end if;
  morreu := _gastar_fome(m.id, 0);
  if morreu then return json_build_object('morreu', true, 'eu', _estado(m.id)); end if;
  if (select fome from moradores where id = m.id) < 15 then
    raise exception 'Você está fraco de fome. Coma alguma coisa antes de trabalhar.';
  end if;
  update moradores set trabalho = t.id, trabalho_inicio = now() where id = m.id;
  return json_build_object('trabalho', t.id, 'duracao', t.duracao, 'salario', t.salario, 'morreu', false, 'eu', _estado(m.id));
end $$;

create or replace function public.terminar_trabalho() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; falta numeric; pago integer; novo_xp integer;
        novo_nivel integer; premio integer := 0; peixes_ganhos integer := 0; morreu boolean;
begin
  m := _eu();
  if m.trabalho is null then raise exception 'Você não está trabalhando.'; end if;
  select * into t from trabalhos where id = m.trabalho;
  falta := t.duracao - extract(epoch from (now() - m.trabalho_inicio));
  if falta > 1 then raise exception 'Ainda faltam % segundos de turno.', ceil(falta); end if;
  pago := round(t.salario * (1 + 0.02 * (m.nivel - 1)));          -- +2% por nível
  if t.id = 'pescador' then peixes_ganhos := 1 + (random() < 0.4)::integer; end if;
  novo_xp := m.xp + t.xp;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;  -- R$ 50 × nível
  end if;
  update moradores set dinheiro = dinheiro + pago + premio, xp = novo_xp, nivel = novo_nivel,
    peixes = peixes + peixes_ganhos, trabalho = null, trabalho_inicio = null, turnos = turnos + 1
  where id = m.id;
  morreu := _gastar_fome(m.id, t.fome);
  return json_build_object('pago', pago, 'xp_ganho', t.xp, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'peixes_ganhos', peixes_ganhos, 'morreu', morreu, 'eu', _estado(m.id));
end $$;

create or replace function public.largar_trabalho() returns void
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  update moradores set trabalho = null, trabalho_inicio = null where id = m.id;
end $$;

create or replace function public.comprar(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; morreu boolean;
begin
  m := _eu();
  select * into i from loja where id = p_item and tipo = 'consumo';
  if not found then raise exception 'Isso não está à venda.'; end if;
  if m.nivel < i.nivel_min then raise exception 'Libera no nível %.', i.nivel_min; end if;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente. Vai trabalhar! 😅'; end if;
  morreu := _gastar_fome(m.id, 0);
  update moradores set dinheiro = dinheiro - i.preco, fome = least(100, fome + i.fome) where id = m.id;
  return json_build_object('item', i.id, 'preco', i.preco, 'morreu', morreu, 'eu', _estado(m.id));
end $$;

create or replace function public.vender_peixes() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer;
begin
  m := _eu();
  if m.peixes < 1 then raise exception 'Você não tem peixe para vender.'; end if;
  ganho := m.peixes * 28;
  update moradores set dinheiro = dinheiro + ganho, peixes = 0 where id = m.id;
  return json_build_object('ganho', ganho, 'vendidos', m.peixes, 'eu', _estado(m.id));
end $$;

create or replace function public.comer_fruta(p_arvore integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ultima timestamptz; falta numeric;
begin
  m := _eu();
  if p_arvore < 1 or p_arvore > 50 then raise exception 'Essa árvore não existe.'; end if;
  select max(quando) into ultima from frutas where morador = m.id;
  if ultima is not null and now() - ultima < interval '20 seconds' then
    raise exception 'Calma, ainda está mastigando a última fruta.';
  end if;
  select 180 - extract(epoch from (now() - quando)) into falta from frutas where morador = m.id and arvore = p_arvore;
  if falta is not null and falta > 0 then raise exception 'Essa árvore ainda não tem fruta madura (faltam % s).', ceil(falta); end if;
  perform _gastar_fome(m.id, 0);
  insert into frutas(morador, arvore, quando) values (m.id, p_arvore, now())
    on conflict (morador, arvore) do update set quando = now();
  update moradores set fome = least(100, fome + 10) where id = m.id;
  return json_build_object('arvore', p_arvore, 'espera', 180, 'eu', _estado(m.id));
end $$;

create or replace function public.comprar_carro(p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja;
begin
  m := _eu();
  select * into i from loja where id = p_carro and tipo = 'carro';
  if not found then raise exception 'Esse carro não existe.'; end if;
  if m.nivel < i.nivel_min then raise exception 'Esse carro libera no nível %.', i.nivel_min; end if;
  if p_carro = any(m.carros) then raise exception 'Você já tem esse carro.'; end if;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente para esse carro.'; end if;
  update moradores set dinheiro = dinheiro - i.preco, carros = array_append(carros, i.id), carro = i.id where id = m.id;
  return json_build_object('carro', i.id, 'eu', _estado(m.id));
end $$;

create or replace function public.usar_carro(p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_carro is not null and not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  update moradores set carro = p_carro where id = m.id;
  update vagas set carro = p_carro where morador = m.id and p_carro is not null;
  return json_build_object('carro', p_carro);
end $$;

-- Estacionar: um carro por vaga e uma vaga por pessoa. A vaga de quem sumiu do jogo
-- há mais de 30 minutos fica livre. A garagem de uma casa é só do dono da casa.
create or replace function public.estacionar(p_vaga text, p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; v public.vagas; dono_casa uuid; visto timestamptz;
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  select * into v from vagas where id = p_vaga for update;
  if not found then raise exception 'Essa vaga não existe.'; end if;
  if v.casa is not null then
    select dono into dono_casa from casas where id = v.casa;
    if dono_casa is distinct from m.id then raise exception 'Essa garagem é de outra pessoa.'; end if;
  elsif v.morador is not null and v.morador <> m.id then
    select visto_em into visto from moradores where id = v.morador;
    if visto > now() - interval '30 minutes' then raise exception 'Vaga ocupada.'; end if;
  end if;
  update vagas set morador = null, carro = null, desde = null where morador = m.id and id <> p_vaga;
  update vagas set morador = m.id, carro = p_carro, desde = now() where id = p_vaga;
  return json_build_object('vaga', p_vaga);
end $$;

create or replace function public.sair_vaga() returns void
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  update vagas set morador = null, carro = null, desde = null where morador = m.id;
end $$;

-- Comprar casa: cada morador tem uma casa. Se já tiver, a antiga volta
-- à venda e você recebe metade do valor dela.
create or replace function public.comprar_casa(p_casa integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; antiga public.casas; volta integer := 0;
begin
  m := _eu();
  select * into c from casas where id = p_casa for update;
  if not found then raise exception 'Essa casa não existe.'; end if;
  if c.dono = m.id then raise exception 'Essa casa já é sua.'; end if;
  if c.dono is not null then raise exception 'Essa casa já tem dono.'; end if;
  if m.nivel < c.nivel_min then raise exception 'Essa casa libera no nível %.', c.nivel_min; end if;
  select * into antiga from casas where dono = m.id and tipo = c.tipo for update;
  if found then volta := antiga.preco / 2; end if;
  if m.dinheiro + volta < c.preco then raise exception 'Dinheiro insuficiente para essa casa.'; end if;
  if antiga.id is not null then
    update casas set dono = null, comprada_em = null, aberta = false where id = antiga.id;
    update vagas set morador = null, carro = null, desde = null where casa = antiga.id;
  end if;
  update casas set dono = m.id, comprada_em = now(), aberta = false where id = c.id;
  update moradores set dinheiro = dinheiro + volta - c.preco, casa_id = c.id where id = m.id;
  return json_build_object('casa', c.id, 'devolvido', volta, 'eu', _estado(m.id));
end $$;

-- Perfil: frase/status, relacionamento, time do coração e Instagram
create or replace function public.atualizar_perfil(p_frase text, p_relacionamento text, p_time text, p_insta text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; f text := nullif(btrim(coalesce(p_frase,'')), ''); tm text := nullif(btrim(coalesce(p_time,'')), '');
        ig text := nullif(regexp_replace(btrim(coalesce(p_insta,'')), '^@', ''), ''); r text := nullif(btrim(coalesce(p_relacionamento,'')), '');
begin
  m := _eu();
  if char_length(f) > 60 then raise exception 'A frase pode ter até 60 letras.'; end if;
  if char_length(tm) > 20 then raise exception 'O time pode ter até 20 letras.'; end if;
  if ig is not null and ig !~ '^[A-Za-z0-9._]{1,30}$' then raise exception 'Instagram inválido. Use só letras, números, ponto e _.'; end if;
  if r is not null and r not in ('Solteiro(a)','Namorando','Noivo(a)','Casado(a)','Enrolado(a)','Viúvo(a)','Prefiro não dizer') then
    raise exception 'Status de relacionamento inválido.'; end if;
  update moradores set frase = limpar_texto(f), relacionamento = r, time_coracao = limpar_texto(tm), insta = ig where id = m.id;
  return _estado(m.id);
end $$;

-- Foto: o arquivo vai para o Storage (pasta com o id da pessoa); aqui só guardamos o endereço
create or replace function public.definir_foto(p_foto text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_foto is not null and (char_length(p_foto) > 400 or p_foto !~ ('^https://[a-z0-9.-]+/storage/v1/object/public/fotos/' || m.id::text || '/[A-Za-z0-9._-]+(\?v=[0-9]+)?$')) then
    raise exception 'Foto inválida.';
  end if;
  update moradores set foto = p_foto where id = m.id;
  return _estado(m.id);
end $$;

-- Sinuca: 3 XP por bola encaçapada (até 7 bolas), uma partida valendo a cada 90 segundos
create or replace function public.sinuca(p_bolas integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer; novo_xp integer; novo_nivel integer; premio integer := 0; morreu boolean;
begin
  m := _eu();
  if p_bolas < 0 or p_bolas > 7 then raise exception 'Placar inválido.'; end if;
  if m.sinuca_em is not null and now() - m.sinuca_em < interval '90 seconds' then
    raise exception 'A mesa está ocupada. Próxima partida valendo XP em % s.', ceil(90 - extract(epoch from (now() - m.sinuca_em)));
  end if;
  ganho := p_bolas * 3;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set xp = novo_xp, nivel = novo_nivel, dinheiro = dinheiro + premio, sinuca_em = now() where id = m.id;
  morreu := _gastar_fome(m.id, 2);
  return json_build_object('xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio, 'morreu', morreu, 'eu', _estado(m.id));
end $$;

-- filtro de palavrões (adicione palavras na lista se quiser)
create or replace function public.limpar_texto(t text) returns text
language sql immutable as $$
  select regexp_replace(t,
    '\m(porra|caralho|merda|puta|puto|buceta|boceta|viado|fdp|pqp|arrombado|arrombada|cuzao|cuzão|vagabunda|vagabundo|corno|piranha|desgraçado|desgraçada|otario|otário|babaca|retardado|macaco|cu)\M',
    '***', 'gi')
$$;

create or replace function public.enviar_msg(p_sala integer, p_texto text) returns public.chat
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := btrim(regexp_replace(coalesce(p_texto,''), '\s+', ' ', 'g')); r public.chat;
begin
  m := _eu();
  if char_length(t) = 0 then raise exception 'Mensagem vazia.'; end if;
  t := left(t, 140);
  if m.ultima_msg is not null and now() - m.ultima_msg < interval '1.5 seconds' then
    raise exception 'Calma! Espere um pouquinho para mandar outra.';
  end if;
  if p_sala < 1 or p_sala > 100 then raise exception 'Sala inválida.'; end if;
  update moradores set ultima_msg = now() where id = m.id;
  insert into chat(sala, morador, nome, texto) values (p_sala, m.id, m.nome, limpar_texto(t)) returning * into r;
  return r;
end $$;

create or replace function public.denunciar(p_alvo uuid, p_motivo text) returns void
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_alvo = m.id then raise exception 'Não dá para se denunciar.'; end if;
  if (select count(*) from denuncias where autor = m.id and criado_em > now() - interval '1 hour') >= 10 then
    raise exception 'Muitas denúncias seguidas. Tente mais tarde.';
  end if;
  insert into denuncias(autor, alvo, motivo) values (m.id, p_alvo, left(coalesce(p_motivo,''), 200));
end $$;

-- limpeza: guarda só as últimas 200 mensagens de cada sala
create or replace function public._podar_chat() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  delete from chat where sala = new.sala
    and id not in (select id from chat where sala = new.sala order by id desc limit 200);
  return null;
end $$;
drop trigger if exists podar_chat on public.chat;
create trigger podar_chat after insert on public.chat for each row
  when (new.id % 50 = 0) execute function public._podar_chat();

-- Quem pode chamar as funções: só jogadores logados (inclusive anônimos)
revoke execute on all functions in schema public from public, anon;
grant execute on function
  public.criar_morador(text, text), public.pulso(), public.comecar_trabalho(text), public.terminar_trabalho(),
  public.largar_trabalho(), public.comprar(text), public.vender_peixes(), public.comer_fruta(integer),
  public.comprar_carro(text), public.usar_carro(text), public.estacionar(text, text), public.sair_vaga(),
  public.comprar_casa(integer), public.enviar_msg(integer, text), public.denunciar(uuid, text),
  public.nivel_de(integer), public.xp_do_nivel(integer),
  public.atualizar_perfil(text, text, text, text), public.definir_foto(text), public.sinuca(integer)
to authenticated;
revoke execute on function public._eu(), public._estado(uuid), public._gastar_fome(uuid, numeric), public._podar_chat()
from authenticated;

-- ---------- Tempo real: chat, casas e vagas aparecem na hora ----------
do $$
declare t text;
begin
  foreach t in array array['chat','casas','vagas'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and tablename = t) then
      execute format('alter publication supabase_realtime add table public.%I', t);
    end if;
  end loop;
end $$;

-- ---------- Fotos de perfil (Supabase Storage) ----------
-- Pasta pública "fotos": cada pessoa só envia, troca ou apaga arquivos dentro da pasta com o próprio id.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('fotos', 'fotos', true, 524288, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update set public = true, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "fotos: todos veem" on storage.objects;
create policy "fotos: todos veem" on storage.objects for select using (bucket_id = 'fotos');
drop policy if exists "fotos: dono envia" on storage.objects;
create policy "fotos: dono envia" on storage.objects for insert to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "fotos: dono troca" on storage.objects;
create policy "fotos: dono troca" on storage.objects for update to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text)
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);
drop policy if exists "fotos: dono apaga" on storage.objects;
create policy "fotos: dono apaga" on storage.objects for delete to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------- Limpeza: tira do jogo (e do ranking) os moradores de teste da instalação ----------
-- (desativado para proteger contas) delete from auth.users where id in (select id from public.moradores where nome like 'Teste Claude%');

