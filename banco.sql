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
(1,18000,1),
(2,18000,1),
(3,18000,1),
(4,18000,1),
(5,18000,1),
(6,18000,1),
(7,18000,1),
(8,18000,1),
(9,18000,1),
(10,18000,1),
(11,18000,1),
(12,18000,1),
(13,18000,1),
(14,18000,1),
(15,18000,1),
(16,18000,1),
(17,18000,1),
(18,18000,1),
(19,18000,1),
(20,18000,1),
(21,18000,1),
(22,18000,1),
(23,18000,1),
(24,18000,1),
(25,18000,1),
(26,18000,1),
(27,18000,1),
(28,18000,1),
(29,18000,1),
(30,18000,1),
(31,18000,1),
(32,18000,1),
(33,18000,1),
(34,18000,1),
(35,18000,1),
(36,18000,1),
(37,18000,1),
(38,18000,1),
(39,18000,1),
(40,18000,1),
(41,18000,1),
(42,18000,1),
(43,18000,1),
(44,18000,1),
(45,18000,1),
(46,18000,1),
(47,18000,1),
(48,18000,1),
(49,18000,1),
(50,18000,1),
(51,18000,1),
(52,18000,1),
(53,30000,1),
(54,30000,1),
(55,30000,1),
(56,30000,1),
(57,30000,1),
(58,30000,1),
(59,30000,1),
(60,30000,1),
(61,30000,1),
(62,30000,1),
(63,30000,1),
(64,30000,1),
(65,30000,1),
(66,30000,1),
(67,30000,1),
(68,135000,10),
(69,135000,10),
(70,135000,10),
(71,135000,10),
(72,135000,10),
(73,135000,10),
(74,135000,10),
(75,135000,10),
(76,135000,10),
(77,135000,10),
(78,12000,1),
(79,12000,1),
(80,12000,1),
(81,12000,1),
(82,12000,1),
(83,12000,1),
(84,12000,1),
(85,12000,1),
(86,12000,1),
(87,12000,1),
(88,12000,1),
(89,12000,1),
(90,12000,1),
(91,12000,1),
(92,12000,1),
(93,12000,1),
(94,12000,1),
(95,12000,1),
(96,12000,1),
(97,12000,1),
(98,12000,1),
(99,12000,1),
(100,12000,1),
(101,12000,1),
(102,12000,1),
(103,12000,1),
(104,12000,1),
(105,12000,1),
(106,12000,1),
(107,12000,1),
(108,12000,1),
(109,12000,1)
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

-- ===================== ETAPA 2: VIP, roupas novas, empregos e carros =====================

-- o estado do jogador agora inclui o VIP
create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet)
  from moradores where id = p_id
$$;

-- criar/salvar morador: precisa de conta; aceita o visual antigo (TH) e o novo (TJ); peças 50+ só para VIP
create or replace function public.criar_morador(p_nome text, p_visual text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; n text := btrim(regexp_replace(coalesce(p_nome,''), '\s+', ' ', 'g'));
        v text := upper(coalesce(p_visual,'')); vip boolean;
begin
  if auth.uid() is null then raise exception 'Entre no jogo primeiro.'; end if;
  if coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then raise exception 'Crie sua conta para jogar.'; end if;
  if char_length(n) < 1 or char_length(n) > 22 then raise exception 'O nome precisa ter de 1 a 22 letras.'; end if;
  if v !~ '^(TH[0-9]{7,30}|TJ[0-9]{20,30})$' or (v ~ '^TJ' and length(v) % 2 = 1) then raise exception 'Visual inválido.'; end if;
  if v ~ '^TJ' and exists (select 1 from generate_series(3, length(v) - 1, 2) i where substr(v, i, 2)::int >= 50) then
    select coalesce(vip_ate > now(), false) into vip from moradores where id = auth.uid();
    if not coalesce(vip, false) then raise exception '👑 Essa peça é exclusiva para VIP.'; end if;
  end if;
  n := public.limpar_texto(n);
  -- nome único: ninguém pode usar o nome de outra pessoa (não diferencia maiúsculas, minúsculas nem acentos)
  if n is distinct from (select nome from moradores where id = auth.uid())
     and exists (select 1 from moradores where id <> auth.uid() and lower(translate(nome,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC')) = lower(translate(n,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'))) then
    raise exception 'Já existe um morador com esse nome. Escolha outro.';
  end if;
  insert into moradores(id, nome, visual) values (auth.uid(), n, v)
  on conflict (id) do update set nome = excluded.nome, visual = excluded.visual, visto_em = now(),
    fome_em = case when now() - moradores.visto_em > interval '2 minutes' then now() else moradores.fome_em end
    where not moradores.banido
  returning * into m;
  if m.id is null then raise exception 'Você foi banido da cidade.'; end if;
  return _estado(m.id);
end $$;

-- empregos novos (níveis 13 a 20)
insert into public.trabalhos(id, nome, salario, duracao, nivel_min, xp, fome) values
  ('enfermeiro', 'Enfermeiro(a)',    125,  90, 13, 50, 14),
  ('gerente',    'Gerente do banco', 140, 100, 15, 56, 15),
  ('delegado',   'Delegado(a)',      155, 100, 17, 62, 16),
  ('medico',     'Médico(a)',        175, 110, 19, 70, 16),
  ('prefeito',   'Prefeito(a)',      200, 120, 20, 78, 16)
on conflict (id) do update set nome = excluded.nome, salario = excluded.salario, duracao = excluded.duracao,
  nivel_min = excluded.nivel_min, xp = excluded.xp, fome = excluded.fome;

-- carros novos
insert into public.loja(id, tipo, nome, preco, local, fome, nivel_min) values
  ('sedan',     'carro', 'Sedã',       45000, 'carros', 0, 13),
  ('jipe',      'carro', 'Jipe',       70000, 'carros', 0, 16),
  ('esportivo', 'carro', 'Esportivo', 120000, 'carros', 0, 20)
on conflict (id) do update set nome = excluded.nome, preco = excluded.preco, nivel_min = excluded.nivel_min;

grant execute on function public.criar_morador(text, text) to authenticated;
revoke execute on function public._estado(uuid) from authenticated;

-- =====================================================================
--  EXTRAS (desligados: tire os "--" do começo da linha e rode só ela)
-- =====================================================================
-- DAR VIP por 30 dias:
-- update public.moradores set vip_ate = now() + interval '30 days' where nome = 'NOME DO JOGADOR';
-- TIRAR o VIP:
-- update public.moradores set vip_ate = null where nome = 'NOME DO JOGADOR';

-- ===================== ETAPA 3: benefícios VIP =====================
-- Fome cai 30% mais devagar para VIP (o custo do trabalho continua igual)
create or replace function public._gastar_fome(p_id uuid, p_custo numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare m public.moradores; f numeric; base integer; ritmo numeric;
begin
  select * into m from moradores where id = p_id for update;
  ritmo := case when m.vip_ate > now() then 0.7 else 1 end;
  f := m.fome - least(extract(epoch from (now() - m.fome_em)), 90) / 120.0 * ritmo - p_custo;
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
revoke execute on function public._gastar_fome(uuid, numeric) from authenticated, anon, public;

-- ===================== ETAPA 4: interiores das casas =====================
-- O dono abre ou tranca a porta da casa (aberta = visitantes podem entrar)
create or replace function public.porta_casa(p_casa integer, p_aberta boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if not exists (select 1 from casas where id = p_casa and dono = m.id) then raise exception 'Essa casa não é sua.'; end if;
  update casas set aberta = coalesce(p_aberta, false) where id = p_casa;
  return json_build_object('casa', p_casa, 'aberta', coalesce(p_aberta, false));
end $$;
grant execute on function public.porta_casa(integer, boolean) to authenticated;

-- ===================== ETAPA 5: loja com Pix (Mercado Pago) =====================
-- Produtos pagos com dinheiro de verdade. O preço vale AQUI (o jogo não decide o preço).
create table if not exists public.produtos (
  id     text primary key,
  tipo   text not null check (tipo in ('vip','pet','carro')),
  item   text,                       -- qual pet ou carro
  dias   integer not null default 0, -- dias de VIP
  nome   text not null,
  preco  numeric(10,2) not null check (preco > 0)
);
insert into public.produtos(id, tipo, item, dias, nome, preco) values
  ('vip30',              'vip',   null,           30, 'VIP 30 dias',         9.90),
  ('pet_cachorro',       'pet',   'cachorro',      0, 'Pet Cachorro',        5.90),
  ('pet_gato',           'pet',   'gato',          0, 'Pet Gato',            5.90),
  ('pet_galinha',        'pet',   'galinha',       0, 'Pet Galinha',         5.90),
  ('pet_capivara',       'pet',   'capivara',      0, 'Pet Capivara',        5.90),
  ('pet_papagaio',       'pet',   'papagaio',      0, 'Pet Papagaio',        5.90),
  ('carro_fusca_ouro',   'carro', 'fusca_ouro',    0, 'Fusca Dourado',       10.90),
  ('carro_kombi_tonhao', 'carro', 'kombi_tonhao',  0, 'Caminhonete do Tonhão', 12.90),
  ('carro_neon',         'carro', 'neon',          0, 'Esportivo Neon',      15.90)
on conflict (id) do update set tipo = excluded.tipo, item = excluded.item, dias = excluded.dias,
  nome = excluded.nome, preco = excluded.preco;

create table if not exists public.pedidos (
  id         uuid primary key default gen_random_uuid(),
  morador    uuid not null references public.moradores(id) on delete cascade,
  produto    text not null references public.produtos(id),
  valor      numeric(10,2) not null,
  status     text not null default 'pendente' check (status in ('pendente','entregue','cancelado')),
  mp_id      text,
  criado_em  timestamptz not null default now(),
  pago_em    timestamptz
);
create index if not exists pedidos_morador on public.pedidos(morador, criado_em desc);

alter table public.produtos enable row level security;
alter table public.pedidos  enable row level security;
drop policy if exists "ler produtos" on public.produtos;
create policy "ler produtos" on public.produtos for select using (true);
drop policy if exists "ver meus pedidos" on public.pedidos;
create policy "ver meus pedidos" on public.pedidos for select to authenticated using (morador = auth.uid());
revoke insert, update, delete on public.produtos, public.pedidos from anon, authenticated;

-- Entrega o item de um pedido pago. Só a função do Pix (chave secreta do servidor) chama isto.
create or replace function public._entregar(p_pedido uuid, p_mp_id text, p_valor numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare pd public.pedidos; pr public.produtos;
begin
  select * into pd from pedidos where id = p_pedido for update;
  if not found or pd.status = 'entregue' then return false; end if;
  if p_valor < pd.valor then raise exception 'Valor pago menor que o pedido.'; end if;
  select * into pr from produtos where id = pd.produto;
  if pr.tipo = 'vip' then
    update moradores set vip_ate = greatest(coalesce(vip_ate, now()), now()) + make_interval(days => pr.dias) where id = pd.morador;
  elsif pr.tipo = 'pet' then
    update moradores set pets = case when pr.item = any(pets) then pets else array_append(pets, pr.item) end,
      pet = pr.item where id = pd.morador;
  elsif pr.tipo = 'carro' then
    update moradores set carros = case when pr.item = any(carros) then carros else array_append(carros, pr.item) end where id = pd.morador;
  end if;
  update pedidos set status = 'entregue', pago_em = now(), mp_id = p_mp_id where id = p_pedido;
  return true;
end $$;
revoke execute on function public._entregar(uuid, text, numeric) from public, anon, authenticated;
grant execute on function public._entregar(uuid, text, numeric) to service_role;

-- Escolher qual pet anda com você (só pets que você comprou; null guarda o pet)
create or replace function public.usar_pet(p_pet text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_pet is not null and not (p_pet = any(m.pets)) then raise exception 'Esse pet não é seu.'; end if;
  update moradores set pet = p_pet where id = m.id;
  return json_build_object('pet', p_pet);
end $$;
grant execute on function public.usar_pet(text) to authenticated;

-- ===================== ETAPA 6: perfil social (seguidores e fotos) =====================
create table if not exists public.seguidores (
  seguidor uuid not null references public.moradores(id) on delete cascade,
  seguido  uuid not null references public.moradores(id) on delete cascade,
  criado_em timestamptz not null default now(),
  primary key (seguidor, seguido),
  check (seguidor <> seguido)
);
create index if not exists seguidores_seguido on public.seguidores(seguido);

create table if not exists public.posts (
  id bigserial primary key,
  autor uuid not null references public.moradores(id) on delete cascade,
  url text not null,
  legenda text,
  criado_em timestamptz not null default now()
);
create index if not exists posts_autor on public.posts(autor, criado_em desc);

alter table public.seguidores enable row level security;
alter table public.posts      enable row level security;
drop policy if exists "ler seguidores" on public.seguidores;
create policy "ler seguidores" on public.seguidores for select using (true);
drop policy if exists "ler posts" on public.posts;
create policy "ler posts" on public.posts for select using (true);
revoke insert, update, delete on public.seguidores, public.posts from anon, authenticated;

-- Seguir ou deixar de seguir alguém
create or replace function public.seguir(p_alvo uuid, p_seguir boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_alvo = m.id then raise exception 'Você não pode seguir você mesmo.'; end if;
  if not exists (select 1 from moradores where id = p_alvo) then raise exception 'Morador não encontrado.'; end if;
  if p_seguir then insert into seguidores(seguidor, seguido) values (m.id, p_alvo) on conflict do nothing;
  else delete from seguidores where seguidor = m.id and seguido = p_alvo; end if;
  return json_build_object('seguindo', p_seguir, 'seguidores', (select count(*) from seguidores where seguido = p_alvo));
end $$;
grant execute on function public.seguir(uuid, boolean) to authenticated;

-- Postar foto (o arquivo vai para a pasta "fotos/<seu id>/"); até 10 posts por dia
create or replace function public.postar(p_url text, p_legenda text) returns public.posts
language plpgsql security definer set search_path = public as $$
declare m public.moradores; l text := nullif(btrim(coalesce(p_legenda,'')), ''); r public.posts;
begin
  m := _eu();
  if m.banido then raise exception 'Você foi banido.'; end if;
  if char_length(p_url) > 400 or p_url !~ ('^https://[a-z0-9.-]+/storage/v1/object/public/fotos/' || m.id::text || '/post-[0-9]+\.jpg$') then
    raise exception 'Foto inválida.'; end if;
  if char_length(l) > 120 then raise exception 'A legenda pode ter até 120 letras.'; end if;
  if (select count(*) from posts where autor = m.id and criado_em > now() - interval '1 day') >= 10 then
    raise exception 'Limite de 10 fotos por dia. Volte amanhã!'; end if;
  insert into posts(autor, url, legenda) values (m.id, p_url, limpar_texto(l)) returning * into r;
  return r;
end $$;
grant execute on function public.postar(text, text) to authenticated;

-- Apagar um post seu
create or replace function public.apagar_post(p_id bigint) returns void
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  delete from posts where id = p_id and autor = m.id;
end $$;
grant execute on function public.apagar_post(bigint) to authenticated;

-- ===================== ETAPA 7: empregos pagam por tarefa =====================
-- Cada tarefa concluída paga dinheiro e XP na hora. Quanto maior o salário/XP do emprego e o seu
-- nível acima do mínimo do emprego, mais cada tarefa paga. Máximo de 1 tarefa a cada 2,5 segundos.
alter table public.moradores add column if not exists tarefa_em timestamptz;

create or replace function public.tarefa_feita() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; extra integer; pago integer; ganho integer; novo_xp integer;
        novo_nivel integer; premio integer := 0; peixes_ganhos integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is null then raise exception 'Você não está trabalhando.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '2.5 seconds' then
    raise exception 'Calma! Uma tarefa de cada vez.';
  end if;
  select * into t from trabalhos where id = m.trabalho;
  extra := greatest(0, m.nivel - t.nivel_min);
  pago  := round(t.salario / 6.0 * (1 + 0.06 * extra));
  ganho := greatest(1, round(t.xp / 5.0 * (1 + 0.04 * extra)));  -- XP por tarefa (era /6, /20, /10, /4)
  if t.id = 'pescador' then pago := 0; peixes_ganhos := (random() < 0.6)::integer; end if;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + pago + premio, xp = novo_xp, nivel = novo_nivel,
    peixes = peixes + peixes_ganhos, tarefa_em = now() where id = m.id;
  morreu := _gastar_fome(m.id, t.fome / 6.0);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', pago, 'xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'peixes_ganhos', peixes_ganhos, 'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;
grant execute on function public.tarefa_feita() to authenticated;

-- ===================== ETAPA 8: cor dos carros (escolhida na concessionária) =====================
alter table public.moradores add column if not exists carro_cores jsonb not null default '{}'::jsonb;

create or replace function public.cor_carro(p_carro text, p_cor text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  if p_cor not in ('#3c78d8','#c0392b','#2b2b30','#eeeeee','#aeb3b8','#f1c40f','#27ae60','#e67e22','#e84393','#7b241c') then
    raise exception 'Cor inválida.'; end if;
  update moradores set carro_cores = carro_cores || jsonb_build_object(p_carro, p_cor) where id = m.id;
  return json_build_object('ok', true);
end $$;
grant execute on function public.cor_carro(text, text) to authenticated;

-- ===================== ETAPA 9: mochila (inventário) =====================
alter table public.moradores add column if not exists mochila jsonb not null default '{}'::jsonb;

-- Compra e guarda na mochila (até 20 de cada)
create or replace function public.guardar_item(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; q integer;
begin
  m := _eu();
  select * into i from loja where id = p_item and tipo = 'consumo';
  if not found or p_item = 'rodada' then raise exception 'Isso não dá para guardar.'; end if;
  if m.nivel < i.nivel_min then raise exception 'Libera no nível %.', i.nivel_min; end if;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente. Vai trabalhar! 😅'; end if;
  q := coalesce((m.mochila->>p_item)::integer, 0);
  if q >= 20 then raise exception 'Sua mochila já tem 20 desse item.'; end if;
  update moradores set dinheiro = dinheiro - i.preco, mochila = mochila || jsonb_build_object(p_item, q + 1) where id = m.id;
  return json_build_object('item', i.id, 'mochila', (select mochila from moradores where id = m.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.guardar_item(text) to authenticated;

-- Usa um item da mochila (come ou bebe em qualquer lugar)
create or replace function public.usar_item(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; q integer; morreu boolean;
begin
  m := _eu();
  q := coalesce((m.mochila->>p_item)::integer, 0);
  if q <= 0 then raise exception 'Você não tem isso na mochila.'; end if;
  select * into i from loja where id = p_item;
  morreu := _gastar_fome(m.id, 0);
  update moradores set fome = least(100, fome + coalesce(i.fome, 0)),
    mochila = case when q > 1 then mochila || jsonb_build_object(p_item, q - 1) else mochila - p_item end
  where id = m.id;
  return json_build_object('item', p_item, 'mochila', (select mochila from moradores where id = m.id), 'morreu', morreu, 'eu', _estado(m.id));
end $$;
grant execute on function public.usar_item(text) to authenticated;

-- ===================== ETAPA 10: prefeito da cidade =====================
create table if not exists public.cidade (
  id integer primary key default 1 check (id = 1),
  prefeito uuid references public.moradores(id) on delete set null,
  desde timestamptz
);
insert into public.cidade(id) values (1) on conflict (id) do nothing;
alter table public.cidade enable row level security;
drop policy if exists "ler cidade" on public.cidade;
create policy "ler cidade" on public.cidade for select using (true);
revoke insert, update, delete on public.cidade from anon, authenticated;
update public.trabalhos set nivel_min = 1 where id = 'prefeito';

-- Assume o cargo: só quem tem o maior nível entre os jogadores online
create or replace function public.assumir_prefeitura() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; maior integer; atual public.moradores;
begin
  m := _eu();
  select max(nivel) into maior from moradores where not banido and visto_em > now() - interval '8 minutes';
  if m.nivel < coalesce(maior, 0) then
    raise exception 'Só quem tem o MAIOR nível online pode ser prefeito (agora é o nível %).', maior; end if;
  select mo.* into atual from cidade c join moradores mo on mo.id = c.prefeito where c.id = 1;
  if atual.id = m.id then raise exception 'Você já é o prefeito!'; end if;
  if atual.id is not null and atual.visto_em > now() - interval '8 minutes' and atual.nivel >= m.nivel then
    raise exception 'O prefeito % está online e tem nível igual ou maior.', atual.nome; end if;
  update cidade set prefeito = m.id, desde = now() where id = 1;
  return json_build_object('prefeito', m.id, 'nome', m.nome);
end $$;
grant execute on function public.assumir_prefeitura() to authenticated;

create or replace function public.comecar_trabalho(p_trabalho text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; morreu boolean;
begin
  m := _eu();
  select * into t from trabalhos where id = p_trabalho;
  if not found then raise exception 'Esse trabalho não existe.'; end if;
  if m.nivel < t.nivel_min then raise exception 'Esse trabalho libera no nível %.', t.nivel_min; end if;
  if t.id = 'prefeito' and coalesce((select prefeito from cidade where id = 1)::text, '') <> m.id::text then
    raise exception 'Só o prefeito da cidade trabalha aqui. Vá na prefeitura e assuma o cargo!'; end if;
  morreu := _gastar_fome(m.id, 0);
  if morreu then return json_build_object('morreu', true, 'eu', _estado(m.id)); end if;
  if (select fome from moradores where id = m.id) < 15 then
    raise exception 'Você está fraco de fome. Coma alguma coisa antes de trabalhar.';
  end if;
  update moradores set trabalho = t.id, trabalho_inicio = now() where id = m.id;
  return json_build_object('trabalho', t.id, 'duracao', t.duracao, 'salario', t.salario, 'morreu', false, 'eu', _estado(m.id));
end $$;

-- ===================== ETAPA 11: painel do administrador e venda de carros =====================
alter table public.moradores add column if not exists admin boolean not null default false;

create or replace function public._adm() returns public.moradores
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if not m.admin then raise exception 'Só o administrador pode fazer isso.'; end if;
  return m;
end $$;
revoke execute on function public._adm() from public, anon, authenticated;

create or replace function public._alvo(p_nome text) returns public.moradores
language plpgsql security definer set search_path = public as $$
declare a public.moradores;
begin
  select * into a from moradores where lower(nome) = lower(btrim(p_nome)) limit 1 for update;
  if not found then raise exception 'Jogador "%" não encontrado.', p_nome; end if;
  return a;
end $$;
revoke execute on function public._alvo(text) from public, anon, authenticated;

-- uma função só para o painel: p_acao = dinheiro | vip | pet | carro | casa | banir | desbanir | tirar_casa
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
  elsif p_acao = 'banir' then
    update moradores set banido = true where id = a.id;
  elsif p_acao = 'desbanir' then
    update moradores set banido = false where id = a.id;
  else raise exception 'Ação desconhecida.'; end if;
  return json_build_object('ok', true, 'id', a.id, 'nome', a.nome);
end $$;
grant execute on function public.admin_acao(text, text, text) to authenticated;

-- vender o carro para a concessionária (metade do preço)
create or replace function public.vender_carro_loja(p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; v integer;
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  select * into i from loja where id = p_carro and tipo = 'carro';
  if not found then raise exception 'A concessionária não compra esse carro (é da loja VIP). Venda para outro jogador!'; end if;
  v := i.preco / 2;
  update vagas set morador = null, carro = null, desde = null where morador = m.id and carro = p_carro;
  update moradores set carros = array_remove(carros, p_carro), carro = case when carro = p_carro then null else carro end,
    carro_cores = carro_cores - p_carro, dinheiro = dinheiro + v where id = m.id;
  return json_build_object('recebido', v, 'eu', _estado(m.id));
end $$;
grant execute on function public.vender_carro_loja(text) to authenticated;

-- propostas de venda entre jogadores
create table if not exists public.propostas (
  id bigserial primary key,
  vendedor uuid not null references public.moradores(id) on delete cascade,
  comprador uuid not null references public.moradores(id) on delete cascade,
  carro text not null,
  valor integer not null check (valor >= 0),
  criado_em timestamptz not null default now()
);
alter table public.propostas enable row level security;
revoke insert, update, delete on public.propostas from anon, authenticated;

create or replace function public.propor_venda(p_nome text, p_carro text, p_valor integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; b public.moradores; pid bigint;
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  if p_valor < 0 or p_valor > 10000000 then raise exception 'Valor inválido.'; end if;
  select * into b from moradores where lower(nome) = lower(btrim(p_nome)) limit 1;
  if not found then raise exception 'Jogador "%" não encontrado.', p_nome; end if;
  if b.id = m.id then raise exception 'Não dá para vender para você mesmo.'; end if;
  if p_carro = any(b.carros) then raise exception '% já tem esse carro.', b.nome; end if;
  delete from propostas where vendedor = m.id and carro = p_carro;
  insert into propostas(vendedor, comprador, carro, valor) values (m.id, b.id, p_carro, p_valor) returning id into pid;
  return json_build_object('id', pid, 'comprador', b.id, 'nome', b.nome);
end $$;
grant execute on function public.propor_venda(text, text, integer) to authenticated;

create or replace function public.responder_proposta(p_id bigint, p_aceitar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; p public.propostas; v public.moradores; cor text;
begin
  m := _eu();
  select * into p from propostas where id = p_id and comprador = m.id for update;
  if not found then raise exception 'Essa proposta não existe mais.'; end if;
  delete from propostas where id = p.id;
  if not p_aceitar then return json_build_object('ok', false); end if;
  if p.criado_em < now() - interval '30 minutes' then raise exception 'A proposta expirou.'; end if;
  select * into v from moradores where id = p.vendedor for update;
  if not (p.carro = any(v.carros)) then raise exception 'O vendedor não tem mais esse carro.'; end if;
  if p.carro = any(m.carros) then raise exception 'Você já tem esse carro.'; end if;
  if m.dinheiro < p.valor then raise exception 'Dinheiro insuficiente.'; end if;
  cor := v.carro_cores->>p.carro;
  update vagas set morador = null, carro = null, desde = null where morador = v.id and carro = p.carro;
  update moradores set carros = array_remove(carros, p.carro), carro = case when carro = p.carro then null else carro end,
    carro_cores = carro_cores - p.carro, dinheiro = dinheiro + p.valor where id = v.id;
  update moradores set carros = array_append(carros, p.carro), carro = p.carro, dinheiro = dinheiro - p.valor,
    carro_cores = case when cor is null then carro_cores else carro_cores || jsonb_build_object(p.carro, cor) end where id = m.id;
  return json_build_object('ok', true, 'carro', p.carro, 'eu', _estado(m.id));
end $$;
grant execute on function public.responder_proposta(bigint, boolean) to authenticated;
-- ===================== ETAPA 13: sede e comidas novas =====================
alter table public.moradores add column if not exists sede numeric not null default 100;
alter table public.loja add column if not exists sede integer not null default 0;   -- quanto mata a sede

-- bebidas que já existiam agora matam a sede
update public.loja set sede = 25 where id = 'cerveja';
update public.loja set sede = 10 where id = 'pinga';
update public.loja set sede = 30 where id = 'guarana';
update public.loja set sede = 12 where id = 'cafe';
update public.loja set sede = 25 where id = 'rodada';

-- comidas e bebidas novas (baratas)
insert into public.loja(id, tipo, nome, preco, local, fome, sede, nivel_min) values
  ('agua',      'consumo', 'uma garrafa de água',     3, 'mercadinho',  0, 40, 1),
  ('banana',    'consumo', 'um cacho de banana',      3, 'mercadinho', 10,  2, 1),
  ('laranja',   'consumo', 'umas laranjas',           4, 'mercadinho',  8, 15, 1),
  ('melancia',  'consumo', 'uma fatia de melancia',   5, 'mercadinho', 10, 25, 1),
  ('biscoito',  'consumo', 'um pacote de biscoito',   6, 'mercadinho', 15,  0, 1),
  ('queijo',    'consumo', 'um pedaço de queijo',     9, 'mercadinho', 22,  0, 1),
  ('sanduiche', 'consumo', 'um sanduíche natural',   12, 'mercadinho', 32,  5, 1),
  ('suco',      'consumo', 'um suco de laranja',      6, 'padaria',     4, 35, 1),
  ('agua_bar',  'consumo', 'um copo de água',         2, 'bar',         0, 30, 1)
on conflict (id) do update set nome = excluded.nome, preco = excluded.preco, local = excluded.local,
  fome = excluded.fome, sede = excluded.sede;

-- fome e sede caem juntas (a sede um pouco mais rápido). Se uma das duas zerar, desmaia.
create or replace function public._gastar_fome(p_id uuid, p_custo numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare m public.moradores; f numeric; s numeric; seg numeric; base integer; ritmo numeric;
begin
  select * into m from moradores where id = p_id for update;
  ritmo := case when m.vip_ate > now() then 0.7 else 1 end;
  seg := least(extract(epoch from (now() - m.fome_em)), 90);
  f := m.fome - seg / 120.0 * ritmo - p_custo;
  s := m.sede - seg / 90.0 * ritmo - p_custo * 0.8;
  if f <= 0 or s <= 0 then
    base := xp_do_nivel(m.nivel);
    update moradores set fome = 50, sede = 50, fome_em = now(), visto_em = now(),
      xp = base + floor((m.xp - base) * 0.7), dinheiro = greatest(0, dinheiro - 30),
      mortes = mortes + 1, trabalho = null, trabalho_inicio = null
    where id = p_id;
    return true;
  end if;
  update moradores set fome = least(100, f), sede = least(100, s), fome_em = now(), visto_em = now() where id = p_id;
  return false;
end $$;
revoke execute on function public._gastar_fome(uuid, numeric) from authenticated, anon, public;

create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'sede', round(sede, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet)
  from moradores where id = p_id
$$;
revoke execute on function public._estado(uuid) from authenticated;

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
  update moradores set dinheiro = dinheiro - i.preco, fome = least(100, fome + i.fome), sede = least(100, sede + i.sede) where id = m.id;
  return json_build_object('item', i.id, 'preco', i.preco, 'morreu', morreu, 'eu', _estado(m.id));
end $$;

create or replace function public.usar_item(p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; i public.loja; q integer; morreu boolean;
begin
  m := _eu();
  q := coalesce((m.mochila->>p_item)::integer, 0);
  if q <= 0 then raise exception 'Você não tem isso na mochila.'; end if;
  select * into i from loja where id = p_item;
  morreu := _gastar_fome(m.id, 0);
  update moradores set fome = least(100, fome + coalesce(i.fome, 0)), sede = least(100, sede + coalesce(i.sede, 0)),
    mochila = case when q > 1 then mochila || jsonb_build_object(p_item, q - 1) else mochila - p_item end
  where id = m.id;
  return json_build_object('item', p_item, 'mochila', (select mochila from moradores where id = m.id), 'morreu', morreu, 'eu', _estado(m.id));
end $$;
grant execute on function public.usar_item(text) to authenticated;

-- ===================== ETAPA 14: prefeito só no nível 20 =====================
update public.trabalhos set nivel_min = 20 where id = 'prefeito';

drop trigger if exists prefeito_top1 on public.moradores;
drop function if exists public._atualiza_prefeito() cascade;

create function public._atualiza_prefeito() returns trigger
language plpgsql security definer set search_path = public as $$
declare novo uuid;
begin
  select id into novo from moradores
   where nivel >= 20 and not coalesce(banido, false)
   order by xp desc, id limit 1;
  insert into cidade(id, prefeito, desde) values (1, novo, case when novo is null then null else now() end)
  on conflict (id) do update set prefeito = excluded.prefeito,
    desde = case when cidade.prefeito is distinct from excluded.prefeito then excluded.desde else cidade.desde end
  where cidade.prefeito is distinct from excluded.prefeito;
  return null;
end $$;
revoke execute on function public._atualiza_prefeito() from authenticated, anon, public;

create trigger prefeito_top1 after insert or update of xp, nivel, banido or delete on public.moradores
for each statement execute function public._atualiza_prefeito();


-- ===================== ETAPA 15: gasolina =====================
alter table public.moradores add column if not exists gasolina numeric not null default 100;

-- preço do tanque cheio de cada carro
create or replace function public._preco_tanque(p_carro text) returns integer
language sql immutable as $$
  select case when p_carro = 'moto' then 120
              when p_carro in ('fusca','kombi','fusca_ouro') then 220
              when p_carro in ('opala','caminhonete','kombi_tonhao') then 300
              else 380 end
$$;

-- o jogo avisa quanto de gasolina sobrou (só pode diminuir)
create or replace function public.salvar_gasolina(p_nivel numeric) returns void
language plpgsql security definer set search_path = public as $$
begin
  update moradores set gasolina = greatest(0, least(gasolina, coalesce(p_nivel, gasolina))) where id = auth.uid();
end $$;
grant execute on function public.salvar_gasolina(numeric) to authenticated;

-- encher o tanque no posto
create or replace function public.abastecer(p_nivel numeric) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; g numeric; custo integer;
begin
  m := _eu();
  if coalesce(array_length(m.carros, 1), 0) = 0 then raise exception 'Você não tem carro.'; end if;
  g := greatest(0, least(m.gasolina, coalesce(p_nivel, m.gasolina)));
  if g >= 99 then raise exception 'O tanque já está cheio.'; end if;
  custo := greatest(2, ceil(_preco_tanque(coalesce(m.carro, m.carros[1])) * (100 - g) / 100.0));
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', custo; end if;
  update moradores set dinheiro = dinheiro - custo, gasolina = 100 where id = m.id;
  return json_build_object('custo', custo, 'eu', _estado(m.id));
end $$;
grant execute on function public.abastecer(numeric) to authenticated;

create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'sede', round(sede, 1), 'gasolina', round(gasolina, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet)
  from moradores where id = p_id
$$;
revoke execute on function public._estado(uuid) from authenticated;

-- ===================== ETAPA 12: coluna da primeira missão (0, 1, 2) =====================
do $$ begin
  if not exists (select 1 from information_schema.columns where table_schema = 'public' and table_name = 'moradores' and column_name = 'missao') then
    alter table public.moradores add column missao smallint not null default 0;
    update public.moradores set missao = 2 where xp > 0 or nivel > 1;
  end if;
end $$;

-- ===================== ETAPA 16: bônus da primeira missão = R$ 100 =====================
create or replace function public.missao_passo(p_passo integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; bonus integer := 0;
begin
  m := _eu();
  if p_passo = 1 then
    if m.missao <> 0 then raise exception 'Essa missão já foi feita.'; end if;
    if m.xp <= 0 then raise exception 'Faça uma tarefa de trabalho primeiro.'; end if;
    bonus := 100;
    update moradores set dinheiro = dinheiro + bonus, missao = 1 where id = m.id;
  else
    if m.missao >= 2 then raise exception 'Essa missão já foi feita.'; end if;
    update moradores set missao = 2 where id = m.id;
  end if;
  return json_build_object('missao', (select missao from moradores where id = m.id), 'bonus', bonus, 'eu', _estado(m.id));
end $$;
grant execute on function public.missao_passo(integer) to authenticated;

-- ===================== ETAPA 17: estampas, loja de roupas e joias =====================
-- visual maior (campo novo Estampa e os próximos)
alter table public.moradores drop constraint if exists moradores_visual_check;
alter table public.moradores add constraint moradores_visual_check check (visual ~ '^(TH[0-9]{7,30}|TJ[0-9]{20,60})$') not valid;
-- (a função criar_morador com a regra de 60 dígitos vai junto na etapa 13, com a conferência do guarda-roupa)

-- guarda-roupa: peças compradas na Tonhão Wear
create table if not exists public.guarda_roupa (
  morador uuid not null references public.moradores(id) on delete cascade,
  peca text not null,          -- roupa_m, roupa_f, calca_m, calca_f, calcado_m, calcado_f, chapeu_m, chapeu_f, extra_m, extra_f (joias), estampa
  item integer not null,
  comprado_em timestamptz not null default now(),
  primary key (morador, peca, item)
);
alter table public.guarda_roupa enable row level security;
drop policy if exists "ver meu guarda-roupa" on public.guarda_roupa;
create policy "ver meu guarda-roupa" on public.guarda_roupa for select to authenticated using (morador = auth.uid());
revoke insert, update, delete on public.guarda_roupa from anon, authenticated;

-- preço igual ao do jogo: as 4 primeiras grátis (2 na estampa), depois R$ 30 subindo 15% por peça; joias e coroa (itens 40 a 49) com preço fixo
create or replace function public.preco_roupa(p_peca text, p_item integer) returns integer
language sql immutable as $$
  select case
    when p_item >= 40 then coalesce((case p_peca
      when 'chapeu_m' then array[50000] when 'chapeu_f' then array[50000]
      when 'extra_m' then array[3000,10000,8000,6000] when 'extra_f' then array[3000,10000,8000,4000,15000,20000,7000] end)[p_item - 39], 999999)
    when p_item < (case when p_peca = 'estampa' then 2 else 4 end) then 0
    else (round(30 * power(1.15, p_item - (case when p_peca = 'estampa' then 2 else 4 end)) / 10) * 10)::integer end
$$;

create or replace function public.comprar_roupa(p_peca text, p_item integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; pr integer;
begin
  m := _eu();
  if p_peca not in ('roupa_m','roupa_f','calca_m','calca_f','calcado_m','calcado_f','chapeu_m','chapeu_f','extra_m','extra_f','estampa') then raise exception 'Peça inválida.'; end if;
  if p_item < 0 or p_item >= 50 then raise exception 'Peça inválida.'; end if;
  if exists (select 1 from guarda_roupa where morador = m.id and peca = p_peca and item = p_item) then return json_build_object('ok', true, 'eu', _estado(m.id)); end if;
  pr := preco_roupa(p_peca, p_item);
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente.'; end if;
  insert into guarda_roupa(morador, peca, item) values (m.id, p_peca, p_item);
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  return json_build_object('ok', true, 'eu', _estado(m.id));
end $$;
grant execute on function public.comprar_roupa(text, integer) to authenticated;

-- ===================== ETAPA 18: nível máximo 50 =====================
create or replace function public.nivel_de(p_xp integer) returns integer
language plpgsql immutable as $$
declare n integer := greatest(1, floor((1 + sqrt(1 + 4.0 * greatest(p_xp, 0) / 25)) / 2)::integer);
begin
  while public.xp_do_nivel(n + 1) <= p_xp loop n := n + 1; end loop;
  while n > 1 and public.xp_do_nivel(n) > p_xp loop n := n - 1; end loop;
  return least(n, 50);  -- nível máximo
end $$;

-- quem estava travado no 20 sobe conforme o XP que já tem
update public.moradores set nivel = public.nivel_de(xp) where public.nivel_de(xp) > nivel;

-- confere: quantos jogadores em cada nível
select nivel, count(*) as jogadores from public.moradores group by nivel order by nivel desc;

-- ===================== ETAPA 19: carros 20% mais caros =====================
update public.loja set preco = 2200 where id = 'moto' and tipo = 'carro';
update public.loja set preco = 3600 where id = 'fusca' and tipo = 'carro';
update public.loja set preco = 6600 where id = 'kombi' and tipo = 'carro';
update public.loja set preco = 14400 where id = 'opala' and tipo = 'carro';
update public.loja set preco = 30000 where id = 'caminhonete' and tipo = 'carro';
update public.loja set preco = 54000 where id = 'sedan' and tipo = 'carro';
update public.loja set preco = 84000 where id = 'jipe' and tipo = 'carro';
update public.loja set preco = 144000 where id = 'esportivo' and tipo = 'carro';

-- ===================== ETAPA 20: oficina (personalizar o carro) =====================
alter table public.moradores add column if not exists carro_mods jsonb not null default '{}'::jsonb;

-- preços iguais aos do jogo; só paga o que mudou
create or replace function public.personalizar_carro(p_carro text, p_cor text, p_roda integer, p_vidro integer, p_pintura integer, p_som boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; at jsonb; custo integer := 0;
  pr_roda integer[] := array[0,2000,4000,8000,3000]; pr_vidro integer[] := array[0,800,1500,2500]; pr_pint integer[] := array[0,2500,4000,6000];
begin
  m := _eu();
  if not (p_carro = any(m.carros)) then raise exception 'Esse carro não é seu.'; end if;
  if p_roda not between 0 and 4 or p_vidro not between 0 and 3 or p_pintura not between 0 and 3 then raise exception 'Opção inválida.'; end if;
  if p_cor is not null and p_cor !~ '^#[0-9a-fA-F]{6}$' then raise exception 'Cor inválida.'; end if;
  at := coalesce(m.carro_mods->p_carro, '{}'::jsonb);
  if p_cor is not null and p_cor is distinct from (m.carro_cores->>p_carro) then custo := custo + 1000; end if;
  if p_roda <> coalesce((at->>'roda')::int, 0) then custo := custo + pr_roda[p_roda + 1]; end if;
  if p_vidro <> coalesce((at->>'vidro')::int, 0) then custo := custo + pr_vidro[p_vidro + 1]; end if;
  if p_pintura <> coalesce((at->>'pintura')::int, 0) then custo := custo + pr_pint[p_pintura + 1]; end if;
  if p_som and not coalesce((at->>'som')::boolean, false) then custo := custo + 5000; end if;
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente.'; end if;
  update moradores set dinheiro = dinheiro - custo,
    carro_cores = case when p_cor is null then carro_cores else carro_cores || jsonb_build_object(p_carro, p_cor) end,
    carro_mods = carro_mods || jsonb_build_object(p_carro, jsonb_build_object('roda', p_roda, 'vidro', p_vidro, 'pintura', p_pintura, 'som', coalesce(p_som, false)))
  where id = m.id;
  return json_build_object('custo', custo, 'eu', _estado(m.id));
end $$;
grant execute on function public.personalizar_carro(text, text, integer, integer, integer, boolean) to authenticated;

-- quem vende o carro perde a personalização dele
create or replace function public._limpa_mods() returns trigger language plpgsql as $$
begin
  new.carro_mods := coalesce((select jsonb_object_agg(k, v) from jsonb_each(new.carro_mods) e(k, v) where k = any(new.carros)), '{}'::jsonb);
  return new;
end $$;
drop trigger if exists limpa_mods on public.moradores;
create trigger limpa_mods before update of carros on public.moradores for each row execute function public._limpa_mods();

select nome, preco from public.loja where tipo = 'carro' order by preco;

-- Amarok (no lugar da Caminhonete) e Lamborghini (no lugar do Esportivo Neon). Quem já tem continua com o carro.
update public.loja set nome = 'Amarok', preco = 45000 where id = 'caminhonete' and tipo = 'carro';
update public.produtos set nome = 'Lamborghini', preco = 19.90 where id = 'carro_neon';

-- Emprego novo: Lixeiro(a) (na Prefeitura, nível 4)
insert into public.trabalhos(id, nome, salario, duracao, nivel_min, xp, fome) values
  ('lixeiro', 'Lixeiro(a)', 65, 60, 4, 25, 12)
on conflict (id) do update set nome = excluded.nome, salario = excluded.salario, duracao = excluded.duracao,
  nivel_min = excluded.nivel_min, xp = excluded.xp, fome = excluded.fome;

-- ===== ETAPA D: casas vazias, loja de móveis (com giro) e geladeira =====
-- Cada casa guarda os móveis colocados (tipo, x, y, andar, giro) e o que tem na geladeira.
alter table public.casas add column if not exists moveis jsonb not null default '[]'::jsonb;
alter table public.casas add column if not exists geladeira jsonb not null default '{}'::jsonb;
drop function if exists public.comprar_movel(text, integer, integer, integer);
drop function if exists public.mexer_movel(integer, integer, integer, boolean);
drop function if exists public.comprar_movel(text, integer, integer, integer, integer);
drop function if exists public.mexer_movel(integer, integer, integer, integer, boolean);
drop function if exists public.geladeira(text, boolean);
drop function if exists public.guardar_movel(integer);
drop function if exists public.colocar_movel(integer, integer, integer, integer, integer);

-- Preços dos móveis (dinheiro do jogo). O preço vale aqui, não no jogo.
create or replace function public.preco_movel(p_tipo text) returns integer
language sql immutable as $$
  select case p_tipo
    when 'parede' then 200 when 'porta' then 600
    when 'caixote' then 80 when 'cadeira' then 150 when 'planta' then 250 when 'colchao' then 300
    when 'tapete' then 400 when 'abajur' then 350 when 'criado' then 450 when 'mesinha' then 500
    when 'mesa' then 900 when 'pia' then 1100 when 'estante' then 1200 when 'fogao' then 1300
    when 'poltrona' then 1400 when 'armario' then 1600 when 'geladeira' then 1800 when 'sofa' then 2200
    when 'tv' then 2500 when 'cama' then 3000 when 'somcx' then 3000 when 'led' then 2000
    when 'aquario' then 6000 when 'homet' then 9000 when 'jukebox' then 12000 else null end
$$;

create or replace function public.comprar_movel(p_casa integer, p_tipo text, p_x integer, p_y integer, p_andar integer, p_r integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pr integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  pr := preco_movel(p_tipo);
  if pr is null then raise exception 'Móvel inválido.'; end if;
  if p_x < 0 or p_x > 30 or p_y < 0 or p_y > 30 or p_andar not in (0, 1) or p_r not between 0 and 3 then raise exception 'Lugar inválido.'; end if;
  if jsonb_array_length(c.moveis) >= 80 then raise exception 'Sua casa já tem móveis demais (máximo 80).'; end if;
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', pr; end if;
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  update casas set moveis = moveis || jsonb_build_array(jsonb_build_object('t', p_tipo, 'x', p_x, 'y', p_y, 'a', p_andar, 'r', p_r)) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;

-- Mover/girar um móvel (de graça) ou vender de volta (devolve metade do preço)
create or replace function public.mexer_movel(p_casa integer, p_i integer, p_x integer, p_y integer, p_r integer, p_vender boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; e jsonb;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  e := c.moveis -> p_i;
  if p_vender then
    update moradores set dinheiro = dinheiro + coalesce(preco_movel(e->>'t'), 0) / 2 where id = m.id;
    update casas set moveis = moveis - p_i where id = c.id;
  else
    if p_x < 0 or p_x > 30 or p_y < 0 or p_y > 30 or p_r not between 0 and 3 then raise exception 'Lugar inválido.'; end if;
    update casas set moveis = jsonb_set(moveis, array[p_i::text], (e - 'g') || jsonb_build_object('x', p_x, 'y', p_y, 'r', p_r)) where id = c.id;
  end if;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;

-- Geladeira: guarda um item da mochila ou pega de volta para a mochila (só o dono)
create or replace function public.geladeira(p_casa integer, p_item text, p_guardar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; q integer; g integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  if not exists (select 1 from jsonb_array_elements(c.moveis) e where e->>'t' = 'geladeira') then
    raise exception 'Sua casa não tem geladeira. Compre uma na loja de móveis!'; end if;
  if not exists (select 1 from loja where id = p_item and tipo = 'consumo') then raise exception 'Item inválido.'; end if;
  q := coalesce((m.mochila->>p_item)::integer, 0);
  g := coalesce((c.geladeira->>p_item)::integer, 0);
  if p_guardar then
    if q <= 0 then raise exception 'Você não tem isso na mochila.'; end if;
    if g >= 30 then raise exception 'A geladeira já tem 30 desse item.'; end if;
    update moradores set mochila = case when q - 1 > 0 then mochila || jsonb_build_object(p_item, q - 1) else mochila - p_item end where id = m.id;
    update casas set geladeira = geladeira || jsonb_build_object(p_item, g + 1) where id = c.id;
  else
    if g <= 0 then raise exception 'A geladeira não tem isso.'; end if;
    if q >= 20 then raise exception 'Sua mochila já tem 20 desse item.'; end if;
    update moradores set mochila = mochila || jsonb_build_object(p_item, q + 1) where id = m.id;
    update casas set geladeira = case when g - 1 > 0 then geladeira || jsonb_build_object(p_item, g - 1) else geladeira - p_item end where id = c.id;
  end if;
  return json_build_object('geladeira', (select geladeira from casas where id = c.id), 'mochila', (select mochila from moradores where id = m.id), 'eu', _estado(m.id));
end $$;

grant execute on function public.comprar_movel(integer, text, integer, integer, integer, integer) to authenticated;
grant execute on function public.mexer_movel(integer, integer, integer, integer, integer, boolean) to authenticated;
grant execute on function public.geladeira(integer, text, boolean) to authenticated;

-- Guardar um móvel no inventário da casa (some do chão) ou tirar de lá (volta ao ser colocado)
create or replace function public.guardar_movel(p_casa integer, p_i integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  update casas set moveis = jsonb_set(moveis, array[p_i::text], (moveis -> p_i) || '{"g": true}'::jsonb) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.guardar_movel(integer, integer) to authenticated;

-- Colocar um móvel guardado no inventário (em qualquer andar)
create or replace function public.colocar_movel(p_casa integer, p_i integer, p_x integer, p_y integer, p_r integer, p_andar integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  if p_x < 0 or p_x > 30 or p_y < 0 or p_y > 30 or p_r not between 0 and 3 or p_andar not in (0, 1) then raise exception 'Lugar inválido.'; end if;
  update casas set moveis = jsonb_set(moveis, array[p_i::text], ((moveis -> p_i) - 'g') || jsonb_build_object('x', p_x, 'y', p_y, 'r', p_r, 'a', p_andar)) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.colocar_movel(integer, integer, integer, integer, integer, integer) to authenticated;

-- ===== ETAPA F: prefeito pelo nível 30, níveis dos empregos, VIP com Lamborghini e novidades =====
-- Prefeito: não é mais automático. Qualquer um no nível 30+ assume se a cidade estiver sem prefeito
-- (ou se o prefeito sumir por mais de 3 dias). Quem é prefeito pode deixar o cargo.
drop trigger if exists prefeito_top1 on public.moradores;
drop function if exists public._atualiza_prefeito() cascade;
create or replace function public.assumir_prefeitura() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; atual public.moradores;
begin
  m := _eu();
  if m.nivel < 30 then raise exception 'A prefeitura libera no nível 30.'; end if;
  select mo.* into atual from cidade c join moradores mo on mo.id = c.prefeito where c.id = 1;
  if atual.id = m.id then raise exception 'Você já é o prefeito!'; end if;
  if atual.id is not null and not atual.banido and atual.visto_em > now() - interval '3 days' then
    raise exception 'A cidade já tem prefeito: %.', atual.nome; end if;
  insert into cidade(id, prefeito, desde) values (1, m.id, now())
  on conflict (id) do update set prefeito = m.id, desde = now();
  return json_build_object('prefeito', m.id, 'nome', m.nome);
end $$;
create or replace function public.deixar_prefeitura() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  update cidade set prefeito = null, desde = null where id = 1 and prefeito = m.id;
  update moradores set trabalho = null where id = m.id and trabalho = 'prefeito';
  return json_build_object('prefeito', null);
end $$;
grant execute on function public.assumir_prefeitura() to authenticated;
grant execute on function public.deixar_prefeitura() to authenticated;

-- Empregos liberam em níveis mais altos (agora vai até o 50)
update public.trabalhos set nivel_min = v.n from (values
  ('bar',1),('mercadinho',1),('posto',3),('pescador',4),('padaria',5),('lixeiro',6),('barbearia',7),
  ('prefeitura',10),('oficina',12),('banco',15),('concessionaria',18),('fabrica',20),('enfermeiro',21),
  ('policia',23),('gerente',25),('delegado',27),('medico',29),('prefeito',30)) as v(id, n)
where trabalhos.id = v.id;

-- VIP: R$ 15,99 e libera a Lamborghini enquanto estiver ativo
update public.produtos set preco = 15.99 where tipo = 'vip';
create or replace function public._tem_carro(m public.moradores, p_carro text) returns boolean
language sql stable as $$
  select p_carro = any(m.carros) or (p_carro = 'neon' and m.vip_ate is not null and m.vip_ate > now())
$$;
create or replace function public.usar_carro(p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_carro is not null and not _tem_carro(m, p_carro) then raise exception 'Esse carro não é seu.'; end if;
  update moradores set carro = p_carro where id = m.id;
  update vagas set carro = p_carro where morador = m.id and p_carro is not null;
  return json_build_object('carro', p_carro);
end $$;

create or replace function public.estacionar(p_vaga text, p_carro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; v public.vagas; dono_casa uuid; visto timestamptz;
begin
  m := _eu();
  if not _tem_carro(m, p_carro) then raise exception 'Esse carro não é seu.'; end if;
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

create or replace function public.cor_carro(p_carro text, p_cor text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if not _tem_carro(m, p_carro) then raise exception 'Esse carro não é seu.'; end if;
  if p_cor not in ('#3c78d8','#c0392b','#2b2b30','#eeeeee','#aeb3b8','#f1c40f','#27ae60','#e67e22','#e84393','#7b241c') then
    raise exception 'Cor inválida.'; end if;
  update moradores set carro_cores = carro_cores || jsonb_build_object(p_carro, p_cor) where id = m.id;
  return json_build_object('ok', true);
end $$;

-- Novidades: guarda a última tela de novidades que a pessoa já viu (aparece só 1 vez)
alter table public.moradores add column if not exists novidades text;
create or replace function public.visto_novidades(p_v text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  update moradores set novidades = left(p_v, 20) where id = m.id;
  return json_build_object('novidades', left(p_v, 20));
end $$;
grant execute on function public.visto_novidades(text) to authenticated;

-- ===================== ETAPA 21: provador não dá mais roupa paga de graça =====================
-- lê os números do visual (TH antigo = 1 dígito por campo; TJ = 2 dígitos por campo)
create or replace function public._vis_nums(v text) returns integer[]
language sql immutable as $$
  select case
    when v ~ '^TH[0-9]+$' then (select array_agg(substr(v, i, 1)::int order by i) from generate_series(3, length(v)) i)
    when v ~ '^TJ[0-9]+$' then (select array_agg(substr(v, i, 2)::int order by i) from generate_series(3, length(v) - 1, 2) i)
  end
$$;

-- confere se a pessoa pode vestir esse visual: peça grátis, peça que já está usando ou peça comprada na loja
create or replace function public._confere_roupas(p_id uuid, v text) returns void
language plpgsql security definer set search_path = public as $$
declare novo integer[] := _vis_nums(v); velho integer[]; ant text; s text; s0 text;
        k integer; i integer; pc text; campos integer[] := array[8, 5, 9, 6, 7, 15]; nomes text[] := array['roupa','calca','calcado','chapeu','extra','estampa'];
begin
  select visual into ant from moradores where id = p_id;
  velho := _vis_nums(coalesce(ant, ''));
  s := case when coalesce(novo[10], 0) = 1 then 'f' else 'm' end;
  s0 := case when coalesce(velho[10], 0) = 1 then 'f' else 'm' end;
  for k in 1..6 loop
    i := coalesce(novo[campos[k]], 0);
    if i >= 50 then continue; end if;  -- peça VIP: conferida à parte
    pc := case when nomes[k] = 'estampa' then 'estampa' else nomes[k] || '_' || s end;
    if preco_roupa(pc, i) = 0 then continue; end if;
    if velho is not null and coalesce(velho[campos[k]], 0) = i and (nomes[k] = 'estampa' or s = s0) then continue; end if;
    if exists (select 1 from guarda_roupa where morador = p_id and guarda_roupa.peca = pc and guarda_roupa.item = i) then continue; end if;
    raise exception '👕 Essa peça é vendida na Loja de Roupas. Compre lá primeiro.';
  end loop;
end $$;
revoke execute on function public._confere_roupas(uuid, text) from public, anon, authenticated;

-- quem já joga fica com as peças que está usando agora (vão para o guarda-roupa)
insert into public.guarda_roupa(morador, peca, item)
select m.id, case when c.n = 'estampa' then 'estampa' else c.n || '_' || case when coalesce(x.a[10], 0) = 1 then 'f' else 'm' end end, x.a[c.p]
from public.moradores m
cross join lateral (select public._vis_nums(m.visual) a) x
cross join (values ('roupa', 8), ('calca', 5), ('calcado', 9), ('chapeu', 6), ('extra', 7), ('estampa', 15)) c(n, p)
where x.a is not null and x.a[c.p] is not null and x.a[c.p] < 50
  and public.preco_roupa(case when c.n = 'estampa' then 'estampa' else c.n || '_' || case when coalesce(x.a[10], 0) = 1 then 'f' else 'm' end end, x.a[c.p]) > 0
on conflict do nothing;

create or replace function public.criar_morador(p_nome text, p_visual text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; n text := btrim(regexp_replace(coalesce(p_nome,''), '\s+', ' ', 'g'));
        v text := upper(coalesce(p_visual,'')); vip boolean;
begin
  if auth.uid() is null then raise exception 'Entre no jogo primeiro.'; end if;
  if coalesce((auth.jwt()->>'is_anonymous')::boolean, false) then raise exception 'Crie sua conta para jogar.'; end if;
  if char_length(n) < 1 or char_length(n) > 22 then raise exception 'O nome precisa ter de 1 a 22 letras.'; end if;
  if v !~ '^(TH[0-9]{7,30}|TJ[0-9]{20,60})$' or (v ~ '^TJ' and length(v) % 2 = 1) then raise exception 'Visual inválido.'; end if;
  if v ~ '^TJ' and exists (select 1 from generate_series(3, length(v) - 1, 2) i where substr(v, i, 2)::int >= 50) then
    select coalesce(vip_ate > now(), false) into vip from moradores where id = auth.uid();
    if not coalesce(vip, false) then raise exception '👑 Essa peça é exclusiva para VIP.'; end if;
  end if;
  perform _confere_roupas(auth.uid(), v);
  n := public.limpar_texto(n);
  if n is distinct from (select nome from moradores where id = auth.uid())
     and exists (select 1 from moradores where id <> auth.uid() and lower(translate(nome,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC')) = lower(translate(n,'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ','aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC'))) then
    raise exception 'Já existe um morador com esse nome. Escolha outro.';
  end if;
  insert into moradores(id, nome, visual) values (auth.uid(), n, v)
  on conflict (id) do update set nome = excluded.nome, visual = excluded.visual, visto_em = now(),
    fome_em = case when now() - moradores.visto_em > interval '2 minutes' then now() else moradores.fome_em end
    where not moradores.banido
  returning * into m;
  if m.id is null then raise exception 'Você foi banido da cidade.'; end if;
  return _estado(m.id);
end $$;
grant execute on function public.criar_morador(text, text) to authenticated;

-- ===================== ETAPA 22: Esportivo passa a se chamar Rover =====================
update public.loja set nome = 'Rover' where id = 'esportivo' and tipo = 'carro';
update public.produtos set nome = 'Lambordini' where id = 'carro_neon';
update public.loja set nome = 'Jipe Renegado' where id = 'jipe' and tipo = 'carro';

-- ===================== ETAPA 23: Ferrarini na loja do Pix (a Lambordini fica só com o VIP) =====================
insert into public.produtos(id, tipo, item, dias, nome, preco) values ('carro_gto', 'carro', 'gto', 0, 'Ferrarini', 19.90)
on conflict (id) do update set nome = excluded.nome, preco = excluded.preco, item = excluded.item;

-- ===================== ETAPA 25: Condomínio Vila Tonhão (apartamentos para comprar ou alugar) e casas 50% mais caras =====================
-- Os apartamentos ficam na mesma tabela das casas (id 1101 a 1444): assim móveis, geladeira e porta funcionam igual.
-- Número: 1000 + bloco×100 + andar×10 + final. Blocos A, B e C = kitnet; bloco D = 2 quartos.
create table if not exists public.migracoes (id text primary key, feita_em timestamptz not null default now());
alter table public.casas add column if not exists alugada boolean not null default false;
alter table public.casas add column if not exists aluguel_ate timestamptz;
alter table public.casas add column if not exists valor_aluguel integer;

-- o "tipo" passa a considerar apartamento e os preços novos (casas 50% mais caras)
drop index if exists public.casas_um_por_tipo;
alter table public.casas drop column if exists tipo;
alter table public.casas add column tipo text generated always as (case when id > 1000 then 'apto' when preco >= 75000 then 'mansao' when preco >= 15000 then 'media' else 'barata' end) stored;
create unique index if not exists casas_um_por_tipo on public.casas(dono, tipo) where dono is not null;

-- casas da cidade 50% mais caras (roda uma vez só)
-- (no banco completo os preços já estão 50% maiores na lista das casas lá em cima)
insert into public.migracoes(id) values ('casas_x15') on conflict do nothing;

-- os 64 apartamentos
insert into public.casas(id, preco, nivel_min, valor_aluguel)
select 1000 + b * 100 + a * 10 + f, case when b <= 3 then 4000 else 6000 end, 1, case when b <= 3 then 250 else 350 end
from generate_series(1, 4) b, generate_series(1, 4) a, generate_series(1, 4) f
on conflict (id) do update set preco = excluded.preco, valor_aluguel = excluded.valor_aluguel;

-- vende os móveis pela metade e deixa o apartamento vago
create or replace function public._vagar_apto(p_casa integer) returns integer
language plpgsql security definer set search_path = public as $$
declare c public.casas; volta integer := 0;
begin
  select * into c from casas where id = p_casa and id > 1000 for update;
  if c.id is null or c.dono is null then return 0; end if;
  select coalesce(sum(coalesce(preco_movel(e->>'t'), 0) / 2), 0) into volta from jsonb_array_elements(c.moveis) e;
  update moradores set dinheiro = dinheiro + volta, casa_id = case when casa_id = c.id then null else casa_id end where id = c.dono;
  update casas set dono = null, comprada_em = null, aberta = false, alugada = false, aluguel_ate = null, moveis = '[]'::jsonb, geladeira = '{}'::jsonb where id = c.id;
  return volta;
end $$;
revoke execute on function public._vagar_apto(integer) from public, anon, authenticated;

-- apartamento alugado e vencido há mais de 3 dias volta a ficar livre
create or replace function public._limpa_aptos() returns void
language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id from casas where id > 1000 and alugada and aluguel_ate < now() - interval '3 days' loop
    perform _vagar_apto(r.id);
  end loop;
end $$;
revoke execute on function public._limpa_aptos() from public, anon, authenticated;

create or replace function public._pegar_apto(p_casa integer, p_alugar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; antigo integer; volta integer := 0; custo integer;
begin
  m := _eu();
  perform _limpa_aptos();
  select * into c from casas where id = p_casa and id > 1000 for update;
  if not found then raise exception 'Esse apartamento não existe.'; end if;
  if c.dono = m.id then raise exception 'Esse apartamento já é seu.'; end if;
  if c.dono is not null then raise exception 'Esse apartamento já tem morador.'; end if;
  if exists (select 1 from casas where dono = m.id and id < 1000) then raise exception 'Quem tem casa na cidade não pode ter apartamento.'; end if;
  custo := case when p_alugar then c.valor_aluguel else c.preco end;
  select id into antigo from casas where dono = m.id and id > 1000;
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', custo; end if;
  if antigo is not null then volta := _vagar_apto(antigo); end if;
  update casas set dono = m.id, comprada_em = now(), aberta = false, alugada = p_alugar,
    aluguel_ate = case when p_alugar then now() + interval '7 days' else null end where id = c.id;
  update moradores set dinheiro = dinheiro - custo, casa_id = c.id where id = m.id;
  return json_build_object('casa', c.id, 'devolvido', volta, 'eu', _estado(m.id));
end $$;
revoke execute on function public._pegar_apto(integer, boolean) from public, anon, authenticated;

create or replace function public.comprar_apto(p_casa integer) returns json
language sql security definer set search_path = public as $$ select _pegar_apto(p_casa, false) $$;
create or replace function public.alugar_apto(p_casa integer) returns json
language sql security definer set search_path = public as $$ select _pegar_apto(p_casa, true) $$;
grant execute on function public.comprar_apto(integer) to authenticated;
grant execute on function public.alugar_apto(integer) to authenticated;

create or replace function public.sair_apto() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c integer; volta integer := 0;
begin
  m := _eu();
  select id into c from casas where dono = m.id and id > 1000;
  if c is null then raise exception 'Você não mora no condomínio.'; end if;
  volta := _vagar_apto(c);
  return json_build_object('devolvido', volta, 'eu', _estado(m.id));
end $$;
grant execute on function public.sair_apto() to authenticated;

-- cobra o aluguel vencido (o jogo chama ao entrar e a cada 10 minutos)
create or replace function public.cobrar_aluguel() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pago integer := 0;
begin
  m := _eu();
  select * into c from casas where dono = m.id and id > 1000 and alugada for update;
  if c.id is null then return json_build_object('ok', true); end if;
  while c.aluguel_ate <= now() and m.dinheiro >= c.valor_aluguel loop
    m.dinheiro := m.dinheiro - c.valor_aluguel; pago := pago + c.valor_aluguel; c.aluguel_ate := c.aluguel_ate + interval '7 days';
  end loop;
  update moradores set dinheiro = m.dinheiro where id = m.id;
  update casas set aluguel_ate = c.aluguel_ate where id = c.id;
  if c.aluguel_ate < now() - interval '3 days' then
    perform _vagar_apto(c.id);
    return json_build_object('despejado', true, 'pago', pago, 'eu', _estado(m.id));
  end if;
  return json_build_object('pago', pago, 'atrasado', c.aluguel_ate < now(), 'valor', c.valor_aluguel, 'eu', _estado(m.id));
end $$;
grant execute on function public.cobrar_aluguel() to authenticated;

-- comprar casa na cidade deixa o apartamento vago (o jogo avisa antes)
create or replace function public.comprar_casa(p_casa integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; antiga public.casas; volta integer := 0; apto integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and id < 1000 for update;
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
  select id into apto from casas where dono = m.id and id > 1000;
  if apto is not null then volta := volta + _vagar_apto(apto); end if;
  update casas set dono = m.id, comprada_em = now(), aberta = false where id = c.id;
  update moradores set dinheiro = dinheiro + volta - c.preco, casa_id = c.id where id = m.id;
  return json_build_object('casa', c.id, 'devolvido', volta, 'eu', _estado(m.id));
end $$;

-- ===================== ETAPA 26: patrulha da polícia sem limite (R$ 50 + 20 XP a cada 1 min e meio) =====================
create or replace function public.ronda_policia() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; novo_xp integer; novo_nivel integer; premio integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is distinct from 'policia' then raise exception 'Você não está de patrulha.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '85 seconds' then
    raise exception 'O próximo pagamento da patrulha ainda não chegou.';
  end if;
  novo_xp := m.xp + 20;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + 50 + premio, xp = novo_xp, nivel = novo_nivel, tarefa_em = now() where id = m.id;
  morreu := _gastar_fome(m.id, 1);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', 50, 'xp_ganho', 20, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;
revoke execute on function public.ronda_policia() from public, anon;
grant execute on function public.ronda_policia() to authenticated;

-- ===================== ETAPA 27: excluir a própria conta (exigência da Play Store) =====================
-- Apaga o login; o personagem, chat, posts, seguidores, roupas, frutas, denúncias, propostas e pedidos somem junto (cascade).
-- A casa/apartamento fica livre e sem móveis. As fotos são apagadas pelo jogo antes (Storage); aqui tenta de novo por garantia.
create or replace function public.excluir_conta() returns json
language plpgsql security definer set search_path = public as $$
declare u uuid := auth.uid();
begin
  if u is null then raise exception 'Entre na sua conta primeiro.'; end if;
  update casas set dono = null, comprada_em = null, aberta = false, alugada = false, aluguel_ate = null,
    moveis = '[]'::jsonb, geladeira = '{}'::jsonb where dono = u;
  update cidade set prefeito = null, desde = null where prefeito = u;
  begin
    delete from storage.objects where bucket_id = 'fotos' and (storage.foldername(name))[1] = u::text;
  exception when others then null;
  end;
  delete from moradores where id = u;
  delete from auth.users where id = u;
  return json_build_object('ok', true);
end $$;
revoke execute on function public.excluir_conta() from public, anon;
grant execute on function public.excluir_conta() to authenticated;

-- ===================== ETAPA 28: Passe da Temporada e VIP turbinado =====================
-- Passe: 20 níveis (300 pontos cada, ~7 h de trabalho = ~2 semanas). Tarefa de emprego = 2 a 15 pontos conforme o tempo (_pontos_tarefa), pagamento da patrulha = 15, VIP ganha +50%.
-- Trilha grátis para todos; trilha premium comprada no Pix (produto passe_T1). Prêmios só visuais ou dinheiro do jogo.
alter table public.produtos drop constraint if exists produtos_tipo_check;
alter table public.produtos add constraint produtos_tipo_check check (tipo in ('vip','pet','carro','passe'));
insert into public.produtos(id, tipo, item, dias, nome, preco) values
  ('vip90', 'vip', null, 90, 'VIP 90 dias', 39.90),
  ('passe_T1', 'passe', 'T1', 0, 'Passe Natal na Vila', 9.90)
on conflict (id) do update set tipo = excluded.tipo, item = excluded.item, dias = excluded.dias, nome = excluded.nome, preco = excluded.preco;

create table if not exists public.passe_temporadas (
  id text primary key, nome text not null, inicio timestamptz not null, fim timestamptz not null
);
alter table public.passe_temporadas add column if not exists carro_pronto boolean not null default false; -- o carro exclusivo só pode ser resgatado quando estiver no jogo
insert into public.passe_temporadas(id, nome, inicio, fim) values ('T1', 'Natal na Vila', '2026-11-17 00:00-03', '2027-01-01 00:00-03')
on conflict (id) do update set nome = excluded.nome, inicio = excluded.inicio, fim = excluded.fim;

create table if not exists public.passe_premios (
  temporada text not null references public.passe_temporadas(id) on delete cascade,
  nivel integer not null check (nivel between 1 and 20),
  trilha text not null check (trilha in ('gratis','premium')),
  premio jsonb not null,   -- {"dinheiro":500} | {"estampa":11} | {"roupa":[item_homem,item_mulher]} (também calca, calcado, chapeu, extra)
  primary key (temporada, nivel, trilha)
);
insert into public.passe_premios(temporada, nivel, trilha, premio) values
  ('T1',1,'gratis','{"dinheiro": 300}'),
  ('T1',1,'premium','{"chapeu": [31, 31]}'),
  ('T1',2,'gratis','{"dinheiro": 300}'),
  ('T1',2,'premium','{"roupa": [22, 17]}'),
  ('T1',3,'gratis','{"dinheiro": 400}'),
  ('T1',3,'premium','{"chapeu": [6, 8]}'),
  ('T1',4,'gratis','{"estampa": 5}'),
  ('T1',4,'premium','{"dinheiro": 3000}'),
  ('T1',5,'gratis','{"chapeu": [30, 30]}'),
  ('T1',5,'premium','{"calca": [15, 22]}'),
  ('T1',6,'gratis','{"dinheiro": 500}'),
  ('T1',6,'premium','{"roupa": [20, 16]}'),
  ('T1',7,'gratis','{"dinheiro": 600}'),
  ('T1',7,'premium','{"calcado": [7, 3]}'),
  ('T1',8,'gratis','{"chapeu": [3, 3]}'),
  ('T1',8,'premium','{"dinheiro": 3000}'),
  ('T1',9,'gratis','{"dinheiro": 700}'),
  ('T1',9,'premium','{"roupa": [19, 15]}'),
  ('T1',10,'gratis','{"dinheiro": 800}'),
  ('T1',10,'premium','{"dinheiro": 10000}'),
  ('T1',11,'gratis','{"dinheiro": 800}'),
  ('T1',11,'premium','{"extra": [6, 5]}'),
  ('T1',12,'gratis','{"estampa": 7}'),
  ('T1',12,'premium','{"rastro": 1}'),
  ('T1',13,'gratis','{"dinheiro": 900}'),
  ('T1',13,'premium','{"roupa": [21, 13]}'),
  ('T1',14,'gratis','{"dinheiro": 1000}'),
  ('T1',14,'premium','{"chapeu": [7, 7]}'),
  ('T1',15,'gratis','{"dinheiro": 1000}'),
  ('T1',15,'premium','{"dinheiro": 4000}'),
  ('T1',16,'gratis','{"roupa": [10, 10]}'),
  ('T1',16,'premium','{"calcado": [6, 7]}'),
  ('T1',17,'gratis','{"dinheiro": 1200}'),
  ('T1',17,'premium','{"roupa": [17, 14]}'),
  ('T1',18,'gratis','{"dinheiro": 1200}'),
  ('T1',18,'premium','{"extra": [7, 4]}'),
  ('T1',19,'gratis','{"dinheiro": 1500}'),
  ('T1',19,'premium','{"dinheiro": 6000}'),
  ('T1',20,'gratis','{"dinheiro": 2000}'),
  ('T1',20,'premium','{"carro": "natal"}')
on conflict (temporada, nivel, trilha) do update set premio = excluded.premio;

create table if not exists public.passe_jogador (
  morador uuid not null references public.moradores(id) on delete cascade,
  temporada text not null references public.passe_temporadas(id) on delete cascade,
  pontos integer not null default 0,
  premium boolean not null default false,
  resgatados text[] not null default '{}',   -- '5g' = nível 5 grátis, '5p' = nível 5 premium
  primary key (morador, temporada)
);
alter table public.passe_temporadas enable row level security;
alter table public.passe_premios enable row level security;
alter table public.passe_jogador enable row level security;
drop policy if exists "ler temporadas" on public.passe_temporadas;
create policy "ler temporadas" on public.passe_temporadas for select using (true);
drop policy if exists "ler premios" on public.passe_premios;
create policy "ler premios" on public.passe_premios for select using (true);
revoke insert, update, delete on public.passe_temporadas, public.passe_premios, public.passe_jogador from anon, authenticated;

create or replace function public._temporada_atual() returns text
language sql stable security definer set search_path = public as $$
  select id from passe_temporadas where now() >= inicio and now() < fim order by inicio desc limit 1
$$;

-- pontos do passe por tarefa conforme o tempo de cada emprego (~15 pontos por minuto em qualquer emprego)
-- ===== bônus a cada 10 tarefas e multa de R$ 25 por erro nos minijogos =====
alter table public.moradores add column if not exists tarefas_seq integer not null default 0;
create or replace function public.erro_tarefa() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; multa integer;
begin
  m := _eu();
  if m.trabalho is null or m.trabalho = 'pescador' then return json_build_object('multa', 0, 'eu', _estado(m.id)); end if;
  multa := least(25, m.dinheiro);
  update moradores set dinheiro = dinheiro - multa where id = m.id;
  return json_build_object('multa', multa, 'eu', _estado(m.id));
end $$;
revoke execute on function public.erro_tarefa() from public, anon;
grant execute on function public.erro_tarefa() to authenticated;

create or replace function public._pontos_tarefa(p_job text) returns integer
language sql immutable as $$
  select case p_job
    when 'bar' then 2
    when 'posto' then 2
    when 'concessionaria' then 2
    when 'barbearia' then 2
    when 'pescador' then 2
    when 'mercadinho' then 3
    when 'oficina' then 3
    when 'prefeito' then 3
    when 'banco' then 4
    when 'delegado' then 4
    when 'gerente' then 6
    when 'lixeiro' then 7
    when 'enfermeiro' then 8
    when 'padaria' then 8
    when 'medico' then 9
    when 'fabrica' then 12
    when 'prefeitura' then 15
    else 3 end
$$;
revoke execute on function public._pontos_tarefa(text) from public, anon;

create or replace function public._passe_pontos(p_morador uuid, p_pontos integer) returns void
language plpgsql security definer set search_path = public as $$
declare t text := _temporada_atual(); vip boolean;
begin
  if t is null then return; end if;
  select coalesce(vip_ate > now(), false) into vip from moradores where id = p_morador;
  insert into passe_jogador(morador, temporada, pontos) values (p_morador, t, least(6000, case when vip then round(p_pontos * 1.5) else p_pontos end))
  on conflict (morador, temporada) do update set pontos = least(6000, passe_jogador.pontos + case when vip then round(p_pontos * 1.5) else p_pontos end);
end $$;
revoke execute on function public._passe_pontos(uuid, integer) from public, anon, authenticated;
revoke execute on function public._temporada_atual() from public, anon;

create or replace function public.meu_passe() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.passe_temporadas; j public.passe_jogador;
begin
  m := _eu();
  select * into t from passe_temporadas where id = _temporada_atual();
  if t.id is null then return json_build_object('temporada', null); end if;
  select * into j from passe_jogador where morador = m.id and temporada = t.id;
  return json_build_object('temporada', t.id, 'nome', t.nome, 'fim', t.fim, 'pontos', coalesce(j.pontos, 0),
    'premium', coalesce(j.premium, false), 'resgatados', coalesce(j.resgatados, '{}'),
    'premios', (select json_agg(json_build_object('nivel', nivel, 'trilha', trilha, 'premio', premio) order by nivel, trilha) from passe_premios where temporada = t.id));
end $$;
grant execute on function public.meu_passe() to authenticated;

-- entrega um prêmio visual (roupa para os dois sexos, estampa) ou dinheiro do jogo
create or replace function public._dar_premio(p_morador uuid, p jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare k text;
begin
  if p ? 'dinheiro' then update moradores set dinheiro = dinheiro + (p->>'dinheiro')::int where id = p_morador; end if;
  if p ? 'carro' then update moradores set carros = case when (p->>'carro') = any(carros) then carros else array_append(carros, p->>'carro') end where id = p_morador; end if;
  if p ? 'estampa' then insert into guarda_roupa(morador, peca, item) values (p_morador, 'estampa', (p->>'estampa')::int) on conflict do nothing; end if;
  if p ? 'rastro' then insert into guarda_roupa(morador, peca, item) values (p_morador, 'rastro', (p->>'rastro')::int) on conflict do nothing; end if;
  foreach k in array array['roupa','calca','calcado','chapeu','extra'] loop
    if p ? k then
      insert into guarda_roupa(morador, peca, item) values (p_morador, k || '_m', (p->k->>0)::int), (p_morador, k || '_f', (p->k->>1)::int) on conflict do nothing;
    end if;
  end loop;
end $$;
revoke execute on function public._dar_premio(uuid, jsonb) from public, anon, authenticated;

create or replace function public.resgatar_passe(p_nivel integer, p_trilha text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t text := _temporada_atual(); j public.passe_jogador; pr jsonb; cod text;
begin
  m := _eu();
  if t is null then raise exception 'Nenhuma temporada ativa agora.'; end if;
  select * into j from passe_jogador where morador = m.id and temporada = t for update;
  if j.morador is null or j.pontos < p_nivel * 300 then raise exception 'Você ainda não chegou nesse nível do passe.'; end if;
  if p_trilha = 'premium' and not j.premium then raise exception 'Esse prêmio é do Passe Premium.'; end if;
  cod := p_nivel || case when p_trilha = 'premium' then 'p' else 'g' end;
  if cod = any(j.resgatados) then raise exception 'Você já pegou esse prêmio.'; end if;
  select premio into pr from passe_premios where temporada = t and nivel = p_nivel and trilha = p_trilha;
  if pr is null then raise exception 'Prêmio não encontrado.'; end if;
  if pr ? 'carro' and not (select carro_pronto from passe_temporadas where id = t) then raise exception 'O carro exclusivo chega em breve!'; end if;
  perform _dar_premio(m.id, pr);
  update passe_jogador set resgatados = array_append(resgatados, cod) where morador = m.id and temporada = t;
  return json_build_object('premio', pr, 'eu', _estado(m.id));
end $$;
grant execute on function public.resgatar_passe(integer, text) to authenticated;

-- presente do mês do VIP (só quem está VIP naquele mês pega; fica para sempre)
create table if not exists public.vip_mensal (mes text primary key, premio jsonb not null);
insert into public.vip_mensal(mes, premio) values
  ('2026-11', '{"roupa":[14,12]}'), ('2026-12', '{"calca":[11,13]}'), ('2027-01', '{"roupa":[18,11]}'),
  ('2027-02', '{"estampa":10}'), ('2027-03', '{"calcado":[5,6]}'), ('2027-04', '{"chapeu":[8,6]}')
on conflict (mes) do update set premio = excluded.premio;
create table if not exists public.vip_presentes (
  morador uuid not null references public.moradores(id) on delete cascade, mes text not null, pego_em timestamptz not null default now(),
  primary key (morador, mes)
);
alter table public.vip_mensal enable row level security;
alter table public.vip_presentes enable row level security;
drop policy if exists "ler vip mensal" on public.vip_mensal;
create policy "ler vip mensal" on public.vip_mensal for select using (true);
revoke insert, update, delete on public.vip_mensal, public.vip_presentes from anon, authenticated;

create or replace function public.presente_vip() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; v_mes text := to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM'); pr jsonb;
begin
  m := _eu();
  if not coalesce(m.vip_ate > now(), false) then raise exception 'O presente do mês é só para quem é VIP.'; end if;
  select premio into pr from vip_mensal where vip_mensal.mes = v_mes;
  if pr is null then raise exception 'O presente deste mês ainda não chegou.'; end if;
  if exists (select 1 from vip_presentes where morador = m.id and vip_presentes.mes = v_mes) then raise exception 'Você já pegou o presente deste mês.'; end if;
  perform _dar_premio(m.id, pr);
  insert into vip_presentes(morador, mes) values (m.id, v_mes);
  return json_build_object('premio', pr, 'mes', v_mes, 'eu', _estado(m.id));
end $$;
grant execute on function public.presente_vip() to authenticated;

create or replace function public.vip_info() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; v_mes text := to_char(now() at time zone 'America/Sao_Paulo', 'YYYY-MM');
begin
  m := _eu();
  return json_build_object('mes', v_mes, 'premio', (select premio from vip_mensal where vip_mensal.mes = v_mes),
    'pego', exists (select 1 from vip_presentes where morador = m.id and vip_presentes.mes = v_mes));
end $$;
grant execute on function public.vip_info() to authenticated;

-- entrega: agora também o passe
create or replace function public._entregar(p_pedido uuid, p_mp_id text, p_valor numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare pd public.pedidos; pr public.produtos;
begin
  select * into pd from pedidos where id = p_pedido for update;
  if not found or pd.status = 'entregue' then return false; end if;
  if p_valor < pd.valor then raise exception 'Valor pago menor que o pedido.'; end if;
  select * into pr from produtos where id = pd.produto;
  if pr.tipo = 'vip' then
    update moradores set vip_ate = greatest(coalesce(vip_ate, now()), now()) + make_interval(days => pr.dias) where id = pd.morador;
  elsif pr.tipo = 'pet' then
    update moradores set pets = case when pr.item = any(pets) then pets else array_append(pets, pr.item) end,
      pet = pr.item where id = pd.morador;
  elsif pr.tipo = 'carro' then
    update moradores set carros = case when pr.item = any(carros) then carros else array_append(carros, pr.item) end where id = pd.morador;
  elsif pr.tipo = 'passe' then
    insert into passe_jogador(morador, temporada, premium) values (pd.morador, pr.item, true)
    on conflict (morador, temporada) do update set premium = true;
  end if;
  update pedidos set status = 'entregue', pago_em = now(), mp_id = p_mp_id where id = p_pedido;
  return true;
end $$;
revoke execute on function public._entregar(uuid, text, numeric) from public, anon, authenticated;
grant execute on function public._entregar(uuid, text, numeric) to service_role;

-- pontos do passe nas tarefas e na patrulha
create or replace function public.tarefa_feita() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; t public.trabalhos; extra integer; pago integer; ganho integer; novo_xp integer;
        novo_nivel integer; premio integer := 0; peixes_ganhos integer := 0; morreu boolean; cansado boolean := false; bonus integer := 0; seq integer;
begin
  m := _eu();
  if m.trabalho is null then raise exception 'Você não está trabalhando.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '2.5 seconds' then
    raise exception 'Calma! Uma tarefa de cada vez.';
  end if;
  select * into t from trabalhos where id = m.trabalho;
  extra := greatest(0, m.nivel - t.nivel_min);
  pago  := round(t.salario / 6.0 * (1 + 0.06 * extra));
  ganho := greatest(1, round(t.xp / 5.0 * (1 + 0.04 * extra)));  -- XP por tarefa (era /6, /20, /10, /4)
  if t.id = 'pescador' then pago := 0; peixes_ganhos := (random() < 0.6)::integer; end if;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + pago + premio, xp = novo_xp, nivel = novo_nivel,
    peixes = peixes + peixes_ganhos, tarefa_em = now() where id = m.id;
  perform _passe_pontos(m.id, _pontos_tarefa(t.id));
  -- bônus de R$ 50 a cada 10 tarefas
  update moradores set tarefas_seq = tarefas_seq + 1 where id = m.id returning tarefas_seq into seq;
  if seq % 10 = 0 then bonus := 50; update moradores set dinheiro = dinheiro + bonus where id = m.id; end if;
  morreu := _gastar_fome(m.id, t.fome / 6.0);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('bonus10', bonus, 'seq', seq, 'pago', pago, 'xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'peixes_ganhos', peixes_ganhos, 'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;


create or replace function public.ronda_policia() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; novo_xp integer; novo_nivel integer; premio integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is distinct from 'policia' then raise exception 'Você não está de patrulha.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '85 seconds' then
    raise exception 'O próximo pagamento da patrulha ainda não chegou.';
  end if;
  novo_xp := m.xp + 20;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + 50 + premio, xp = novo_xp, nivel = novo_nivel, tarefa_em = now() where id = m.id;
  perform _passe_pontos(m.id, 15);
  morreu := _gastar_fome(m.id, 1);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', 50, 'xp_ganho', 20, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;

-- itens exclusivos (30-39) não são vendidos na loja de roupas: só quem ganhou no passe
create or replace function public.preco_roupa(p_peca text, p_item integer) returns integer
language sql immutable as $$
  select case
    when p_item >= 40 then coalesce((case p_peca
      when 'chapeu_m' then array[50000] when 'chapeu_f' then array[50000]
      when 'extra_m' then array[3000,10000,8000,6000] when 'extra_f' then array[3000,10000,8000,4000,15000,20000,7000] end)[p_item - 39], 999999)
    when p_item >= 30 then 999999
    when p_item < (case when p_peca = 'estampa' then 2 else 4 end) then 0
    else (round(30 * power(1.15, p_item - (case when p_peca = 'estampa' then 2 else 4 end)) / 10) * 10)::integer end
$$;
create or replace function public.comprar_roupa(p_peca text, p_item integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; pr integer;
begin
  m := _eu();
  if p_peca not in ('roupa_m','roupa_f','calca_m','calca_f','calcado_m','calcado_f','chapeu_m','chapeu_f','extra_m','extra_f','estampa') then raise exception 'Peça inválida.'; end if;
  if p_item < 0 or p_item >= 50 then raise exception 'Peça inválida.'; end if;
  if p_item >= 30 and p_item < 40 then raise exception 'Esse item é exclusivo do Passe da Temporada.'; end if;
  if exists (select 1 from guarda_roupa where morador = m.id and peca = p_peca and item = p_item) then return json_build_object('ok', true, 'eu', _estado(m.id)); end if;
  pr := preco_roupa(p_peca, p_item);
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente.'; end if;
  insert into guarda_roupa(morador, peca, item) values (m.id, p_peca, p_item);
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  return json_build_object('ok', true, 'eu', _estado(m.id));
end $$;
grant execute on function public.comprar_roupa(text, integer) to authenticated;

-- brilho no chão (rastro): 'ouro' = do VIP, 'natal' = vermelho e verde do Passe Natal na Vila, 'nenhum' = desligado; null = padrão (ouro para VIP)
alter table public.moradores add column if not exists rastro text;
create or replace function public.usar_rastro(p_rastro text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_rastro is not null and p_rastro not in ('ouro','natal','nenhum') then raise exception 'Brilho inválido.'; end if;
  if p_rastro = 'ouro' and not coalesce(m.vip_ate > now(), false) then raise exception 'O brilho dourado é do VIP.'; end if;
  if p_rastro = 'natal' and not exists (select 1 from guarda_roupa where morador = m.id and peca = 'rastro' and item = 1) then raise exception 'O brilho de Natal é do Passe Natal na Vila.'; end if;
  update moradores set rastro = p_rastro where id = m.id;
  return json_build_object('rastro', p_rastro);
end $$;
grant execute on function public.usar_rastro(text) to authenticated;
create or replace function public._estado(p_id uuid) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', id, 'nome', nome, 'visual', visual, 'dinheiro', dinheiro, 'xp', xp, 'nivel', nivel,
    'fome', round(fome, 1), 'sede', round(sede, 1), 'gasolina', round(gasolina, 1), 'peixes', peixes, 'carros', carros, 'carro', carro, 'casa_id', casa_id, 'mortes', mortes,
    'trabalho', trabalho, 'trabalho_inicio', trabalho_inicio, 'foto', foto, 'frase', frase,
    'relacionamento', relacionamento, 'time_coracao', time_coracao, 'insta', insta, 'turnos', turnos, 'vip_ate', vip_ate, 'pets', pets, 'pet', pet, 'rastro', rastro)
  from moradores where id = p_id
$$;
revoke execute on function public._estado(uuid) from authenticated;

-- ===== sinuca: 15 bolas no modo sozinho e XP também no amistoso em dupla =====
create or replace function public.sinuca(p_bolas integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer; novo_xp integer; novo_nivel integer; premio integer := 0; morreu boolean;
begin
  m := _eu();
  if p_bolas < 0 or p_bolas > 15 then raise exception 'Placar inválido.'; end if;
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
grant execute on function public.sinuca(integer) to authenticated;
create or replace function public.sinuca_dupla(p_venceu boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer; novo_xp integer; novo_nivel integer; premio integer := 0;
begin
  m := _eu();
  if m.sinuca_em is not null and now() - m.sinuca_em < interval '90 seconds' then
    raise exception 'XP da sinuca só a cada 90 s.';
  end if;
  ganho := case when p_venceu then 30 else 10 end;
  novo_xp := m.xp + ganho;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set xp = novo_xp, nivel = novo_nivel, dinheiro = dinheiro + premio, sinuca_em = now() where id = m.id;
  return json_build_object('xp_ganho', ganho, 'subiu', novo_nivel - m.nivel, 'premio', premio, 'eu', _estado(m.id));
end $$;
revoke execute on function public.sinuca_dupla(boolean) from public, anon;
grant execute on function public.sinuca_dupla(boolean) to authenticated;

-- aluguel: só grava quando cobrou de verdade (cada gravação em "casas" é avisada a todos os jogadores pelo Realtime)
create or replace function public.cobrar_aluguel() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pago integer := 0;
begin
  m := _eu();
  select * into c from casas where dono = m.id and id > 1000 and alugada for update;
  if c.id is null then return json_build_object('ok', true); end if;
  while c.aluguel_ate <= now() and m.dinheiro >= c.valor_aluguel loop
    m.dinheiro := m.dinheiro - c.valor_aluguel; pago := pago + c.valor_aluguel; c.aluguel_ate := c.aluguel_ate + interval '7 days';
  end loop;
  if pago > 0 then
    update moradores set dinheiro = m.dinheiro where id = m.id;
    update casas set aluguel_ate = c.aluguel_ate where id = c.id;
  end if;
  if c.aluguel_ate < now() - interval '3 days' then
    perform _vagar_apto(c.id);
    return json_build_object('despejado', true, 'pago', pago, 'eu', _estado(m.id));
  end if;
  return json_build_object('pago', pago, 'atrasado', c.aluguel_ate < now(), 'valor', c.valor_aluguel, 'eu', _estado(m.id));
end $$;
grant execute on function public.cobrar_aluguel() to authenticated;


-- etapa 29: carro exclusivo do Passe (Furacão GT) entrou no jogo
update public.passe_temporadas set carro_pronto = true where id = 'T1';

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
    when 'vaso' then 700 when 'piabanho' then 900 when 'chuveiro' then 1500 when 'banheira' then 3200 when 'toalheiro' then 400 when 'armpar' then 1100 when 'micro' then 1300 when 'cafeteira' then 800 when 'balcao' then 2600 when 'churras' then 3500 when 'rede' then 900 when 'cadpraia' then 450 when 'piscina' then 1800 when 'gamer' then 4500 when 'cadgamer' then 2200 when 'sofacurvo' then 4800 when 'sofamod' then 5600 when 'painel' then 2400 when 'mesaredonda' then 1300 when 'leitura' then 2000 when 'camaking' then 6500 when 'beliche' then 2400 when 'penteadeira' then 2100 when 'comoda' then 1500 when 'quadro' then 600 when 'quadro2' then 900 when 'espelho' then 1100 when 'taprd' then 700 when 'cortina' then 800 when 'lumichao' then 900 when 'relogio' then 500 when 'plantag' then 700 when 'trofeu' then 1500 when 'lustre' then 18000 when 'piano' then 28000 when 'estatua' then 15000 when 'sofacouro' then 12000 when 'adega' then 9500 when 'vitrola' then 7500 when 'trono' then 20000 when 'hidro' then 24000 when 'massag' then 16000 when 'arcade' then 14000 when 'aqparede' then 22000 when 'lareira' then 8000 when 'globo' then 6000 when 'neon' then 5000 when 'neon2' then 3500 when 'fonte' then 9000 when 'lava' then 2500 when 'luzteto' then 250 else null end
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

-- ===================== ETAPA 34: Ligar/desligar móveis (lareira, neon, globo, luminárias...) =====================
create or replace function public.ligar_movel(p_casa integer, p_i integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; e jsonb;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id for update;
  if c.id is null then raise exception 'Só o dono da casa liga e desliga.'; end if;
  if p_i < 0 or p_i >= jsonb_array_length(c.moveis) then raise exception 'Móvel não encontrado.'; end if;
  e := c.moveis -> p_i;
  e := jsonb_set(e, '{off}', to_jsonb(not coalesce((e ->> 'off')::boolean, false)));
  update casas set moveis = jsonb_set(moveis, array[p_i::text], e) where id = c.id;
  return json_build_object('moveis', (select moveis from casas where id = c.id));
end $$;
revoke execute on function public.ligar_movel(integer, integer) from public, anon;
grant execute on function public.ligar_movel(integer, integer) to authenticated;

-- ===================== ETAPA 35: Carros novos (Porshe GT e Fiestta) e nomes sem marca =====================
-- Porshe GT entra no lugar do Fusca Dourado (mesmo preço da Ferrarini). Fiestta entra no lugar da Kombi.
-- Amarock (antiga Amarok) passa a custar 123 mil. Nomes trocados para não usar marcas registradas.
update public.loja set nome = 'Fuska'       where id = 'fusca'       and tipo = 'carro';
update public.loja set nome = 'Fiestta'     where id = 'kombi'       and tipo = 'carro';
update public.loja set nome = 'Opalla'   where id = 'opala'       and tipo = 'carro';
update public.loja set nome = 'Amarock', preco = 123000 where id = 'caminhonete' and tipo = 'carro';
update public.loja set nome = 'Jipe Renegado' where id = 'jipe'        and tipo = 'carro';
update public.loja set nome = 'Rovver'    where id = 'esportivo'   and tipo = 'carro';
update public.produtos set nome = 'Porshe GT', preco = 19.90 where id = 'carro_fusca_ouro';
update public.produtos set nome = 'Ferrarini'    where id = 'carro_gto';
update public.produtos set nome = 'Lambordini'  where id = 'carro_neon';

-- ===================== ETAPA 37: Estilo da casa (cor das paredes, piso e janelas) =====================
-- p = cor da parede (0 a 11, R$ 300), c = piso (0 a 13, R$ 600; 12 e 13 só VIP), j = janela (0 a 6, R$ 400)
alter table public.casas add column if not exists estilo jsonb not null default '{}'::jsonb;

create or replace function public.estilo_casa(p_casa integer, p_tipo text, p_v integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; pr integer; mx integer;
begin
  m := _eu();
  select * into c from casas where id = p_casa and dono = m.id for update;
  if c.id is null then raise exception 'Essa casa não é sua.'; end if;
  pr := case p_tipo when 'p' then 300 when 'c' then 600 when 'j' then 400 else null end;
  mx := case p_tipo when 'p' then 11 when 'c' then 13 when 'j' then 6 else null end;
  if pr is null or p_v is null or p_v < 0 or p_v > mx then raise exception 'Opção inválida.'; end if;
  if p_tipo = 'c' and p_v >= 12 and not (m.vip_ate is not null and m.vip_ate > now()) then raise exception 'Esse piso é só para VIP.'; end if;
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', pr; end if;
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  update casas set estilo = coalesce(estilo, '{}'::jsonb) || jsonb_build_object(p_tipo, p_v) where id = c.id;
  return json_build_object('estilo', (select estilo from casas where id = c.id), 'eu', _estado(m.id));
end $$;
revoke execute on function public.estilo_casa(integer, text, integer) from public, anon;
grant execute on function public.estilo_casa(integer, text, integer) to authenticated;

-- ===================== ETAPA 38: avisos de casa e vaga pelo Cloudflare (tira o tempo real do Supabase) =====================
-- Quando uma casa muda de dono/porta ou uma vaga muda, o banco avisa o servidor ao vivo, que avisa todas as salas.
create extension if not exists pg_net;
create or replace function public._aviso_rt() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform net.http_post(url := 'https://vila-tempo-real.obiellsilva.workers.dev/glob',
    body := jsonb_build_object('tb', TG_TABLE_NAME, 'id', NEW.id), headers := '{"Content-Type":"application/json"}'::jsonb);
  return NEW;
exception when others then return NEW;
end $$;
revoke execute on function public._aviso_rt() from public, anon, authenticated;
drop trigger if exists casas_aviso_rt on public.casas;
create trigger casas_aviso_rt after update on public.casas for each row
  when (old.dono is distinct from new.dono or old.aberta is distinct from new.aberta) execute function public._aviso_rt();
drop trigger if exists vagas_aviso_rt on public.vagas;
create trigger vagas_aviso_rt after update on public.vagas for each row
  when (old.morador is distinct from new.morador or old.carro is distinct from new.carro) execute function public._aviso_rt();

-- ===================== ETAPA 39: economia (casas mais caras, Hillux, pacotes de dinheiro) =====================
-- o "tipo" da casa (1 de cada) passa a usar os preços novos
drop index if exists public.casas_um_por_tipo;
alter table public.casas drop column if exists tipo;
alter table public.casas add column tipo text generated always as (case when id > 1000 then 'apto' when preco >= 200000 then 'mansao' when preco >= 40000 then 'media' else 'barata' end) stored;
create unique index if not exists casas_um_por_tipo on public.casas(dono, tipo) where dono is not null;
-- casas da cidade: 12 mil -> 30 mil, 18 mil -> 45 mil, 30 mil -> 75 mil, 135 mil -> 350 mil (roda uma vez só)
do $$ begin
  if not exists (select 1 from migracoes where id = 'casas_eco2') then
    update casas set preco = case when preco < 15000 then 30000 when preco < 25000 then 45000 when preco < 100000 then 75000 else 350000 end where id < 1000;
    insert into migracoes(id) values ('casas_eco2');
  end if;
end $$;
-- apartamentos: kitnet 15 mil (aluguel 1.500/semana), 2 quartos 25 mil (2.500/semana)
update casas set preco = case when ((id - 1000) / 100) <= 3 or (((id - 1000) / 100) > 4 and ((id - 1000) / 100) % 2 = 1) then 15000 else 25000 end,
  valor_aluguel = case when ((id - 1000) / 100) <= 3 or (((id - 1000) / 100) > 4 and ((id - 1000) / 100) % 2 = 1) then 1500 else 2500 end where id > 1000;
alter table public.produtos drop constraint if exists produtos_tipo_check;
alter table public.produtos add constraint produtos_tipo_check check (tipo in ('vip','pet','carro','passe','dinheiro'));
-- Hillux (antiga Caminhonete do Tonhão)
update produtos set nome = 'Hillux', preco = 15.90 where id = 'carro_kombi_tonhao';
-- pacotes de dinheiro do jogo (item = quanto entrega)
insert into produtos(id, tipo, item, dias, nome, preco) values
  ('din10', 'dinheiro', '10000', 0, 'R$ 10 mil do jogo', 9.90),
  ('din20', 'dinheiro', '20000', 0, 'R$ 20 mil do jogo', 18.90),
  ('din50', 'dinheiro', '50000', 0, 'R$ 50 mil do jogo', 44.90),
  ('din100', 'dinheiro', '100000', 0, 'R$ 100 mil do jogo', 84.90)
on conflict (id) do update set tipo = excluded.tipo, item = excluded.item, nome = excluded.nome, preco = excluded.preco;
-- limite: no máximo R$ 100 mil do jogo comprados em 7 dias (conferido quando o Pix é gerado)
create or replace function public._limite_dinheiro() returns trigger
language plpgsql security definer set search_path = public as $$
declare novo integer; ja integer;
begin
  select case when tipo = 'dinheiro' then item::integer else 0 end into novo from produtos where id = NEW.produto;
  if coalesce(novo, 0) = 0 then return NEW; end if;
  select coalesce(sum(pr.item::integer), 0) into ja from pedidos p join produtos pr on pr.id = p.produto
    where p.morador = NEW.morador and pr.tipo = 'dinheiro' and p.status = 'entregue' and p.pago_em > now() - interval '7 days';
  if ja + novo > 100000 then raise exception 'Limite de R$ 100 mil do jogo por semana. Já comprado: R$ %.', ja; end if;
  return NEW;
end $$;
revoke execute on function public._limite_dinheiro() from public, anon, authenticated;
drop trigger if exists pedidos_limite_dinheiro on public.pedidos;
create trigger pedidos_limite_dinheiro before insert on public.pedidos for each row execute function public._limite_dinheiro();
-- entrega do Pix agora também entrega dinheiro
create or replace function public._entregar(p_pedido uuid, p_mp_id text, p_valor numeric) returns boolean
language plpgsql security definer set search_path = public as $$
declare pd public.pedidos; pr public.produtos;
begin
  select * into pd from pedidos where id = p_pedido for update;
  if not found or pd.status = 'entregue' then return false; end if;
  if p_valor < pd.valor then raise exception 'Valor pago menor que o pedido.'; end if;
  select * into pr from produtos where id = pd.produto;
  if pr.tipo = 'vip' then
    update moradores set vip_ate = greatest(coalesce(vip_ate, now()), now()) + make_interval(days => pr.dias) where id = pd.morador;
  elsif pr.tipo = 'pet' then
    update moradores set pets = case when pr.item = any(pets) then pets else array_append(pets, pr.item) end,
      pet = pr.item where id = pd.morador;
  elsif pr.tipo = 'carro' then
    update moradores set carros = case when pr.item = any(carros) then carros else array_append(carros, pr.item) end where id = pd.morador;
  elsif pr.tipo = 'passe' then
    insert into passe_jogador(morador, temporada, premium) values (pd.morador, pr.item, true)
    on conflict (morador, temporada) do update set premium = true;
  elsif pr.tipo = 'dinheiro' then
    update moradores set dinheiro = dinheiro + pr.item::integer where id = pd.morador;
  end if;
  update pedidos set status = 'entregue', pago_em = now(), mp_id = p_mp_id where id = p_pedido;
  return true;
end $$;
revoke execute on function public._entregar(uuid, text, numeric) from public, anon, authenticated;

-- ===================== ETAPA 40: apartamentos sem limite =====================
-- Quando sobram menos de 4 apartamentos livres de um tipo, o banco cria um bloco novo com 16 (E, F, G...).
-- Blocos ímpares a partir do E = kitnet; pares = 2 quartos. Eles ficam nos mesmos prédios do condomínio.
create or replace function public._garante_aptos() returns void
language plpgsql security definer set search_path = public as $$
declare k boolean; livres integer; b integer; tentativas integer := 0;
begin
  foreach k in array array[true, false] loop
    loop
      select count(*) into livres from casas where id > 1000 and dono is null
        and (((id - 1000) / 100) <= 3 or (((id - 1000) / 100) > 4 and ((id - 1000) / 100) % 2 = 1)) = k;
      exit when livres >= 4 or tentativas >= 4;
      tentativas := tentativas + 1;
      select coalesce(max((id - 1000) / 100), 4) + 1 into b from casas where id > 1000;
      if b > 89 then exit; end if;
      insert into casas(id, preco, nivel_min, valor_aluguel)
      select 1000 + b * 100 + a * 10 + f, case when b % 2 = 1 then 15000 else 25000 end, 1, case when b % 2 = 1 then 1500 else 2500 end
      from generate_series(1, 4) a, generate_series(1, 4) f on conflict (id) do nothing;
    end loop;
  end loop;
end $$;
revoke execute on function public._garante_aptos() from public, anon, authenticated;
create or replace function public._pegar_apto(p_casa integer, p_alugar boolean) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.casas; antigo integer; volta integer := 0; custo integer;
begin
  m := _eu();
  perform _limpa_aptos();
  select * into c from casas where id = p_casa and id > 1000 for update;
  if not found then raise exception 'Esse apartamento não existe.'; end if;
  if c.dono = m.id then raise exception 'Esse apartamento já é seu.'; end if;
  if c.dono is not null then raise exception 'Esse apartamento já tem morador.'; end if;
  if exists (select 1 from casas where dono = m.id and id < 1000) then raise exception 'Quem tem casa na cidade não pode ter apartamento.'; end if;
  custo := case when p_alugar then c.valor_aluguel else c.preco end;
  select id into antigo from casas where dono = m.id and id > 1000;
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', custo; end if;
  if antigo is not null then volta := _vagar_apto(antigo); end if;
  update casas set dono = m.id, comprada_em = now(), aberta = false, alugada = p_alugar,
    aluguel_ate = case when p_alugar then now() + interval '7 days' else null end where id = c.id;
  update moradores set dinheiro = dinheiro - custo, casa_id = c.id where id = m.id;
  perform _garante_aptos();
  return json_build_object('casa', c.id, 'devolvido', volta, 'eu', _estado(m.id));
end $$;
revoke execute on function public._pegar_apto(integer, boolean) from public, anon, authenticated;
select _garante_aptos();

-- ===================== ETAPA 41: títulos e conquistas =====================
alter table public.moradores add column if not exists titulo text;
alter table public.moradores add column if not exists titulos text[] not null default '{}';
alter table public.moradores add column if not exists tarefas_total integer not null default 0;
alter table public.moradores add column if not exists ganho_trabalho bigint not null default 0;

-- conta cada tarefa e o dinheiro ganho trabalhando (toda tarefa grava "tarefa_em")
create or replace function public._conta_tarefa() returns trigger
language plpgsql as $$
begin
  new.tarefas_total := coalesce(old.tarefas_total, 0) + 1;
  new.ganho_trabalho := coalesce(old.ganho_trabalho, 0) + greatest(0, new.dinheiro - old.dinheiro);
  return new;
end $$;
drop trigger if exists moradores_conta_tarefa on public.moradores;
create trigger moradores_conta_tarefa before update on public.moradores for each row
  when (new.tarefa_em is distinct from old.tarefa_em) execute function public._conta_tarefa();

-- códigos que dão título (ex.: testadores). Só o dono cria, direto no banco.
create table if not exists public.codigos (id text primary key, titulo text not null, ate timestamptz not null, usos integer not null default 0);
alter table public.codigos enable row level security;
insert into public.codigos(id, titulo, ate) values ('PIONEIRO-VILA', 'pioneiro', '2027-02-28 23:59:59-03') on conflict (id) do nothing;

-- quais títulos a pessoa já conquistou
create or replace function public._titulos_de(p_id uuid) returns text[]
language plpgsql stable security definer set search_path = public as $$
declare m public.moradores; t text[]; gasto numeric; nc integer;
begin
  select * into m from moradores where id = p_id;
  if not found then return '{}'; end if;
  t := coalesce(m.titulos, '{}');
  nc := coalesce(cardinality(m.carros), 0);
  if exists (select 1 from casas where dono = m.id) then t := array_append(t, 'morador'); end if;
  if m.tarefas_total >= 100 then t := array_append(t, 'trabalhador'); end if;
  if m.tarefas_total >= 1000 then t := array_append(t, 'dedicado'); end if;
  if m.tarefas_total >= 5000 then t := array_append(t, 'incansavel'); end if;
  if m.tarefas_total >= 20000 then t := array_append(t, 'imparavel'); end if;
  if nc >= 1 then t := array_append(t, 'motorista'); end if;
  if nc >= 5 then t := array_append(t, 'colecionador'); end if;
  if m.nivel >= 20 then t := array_append(t, 'veterano'); end if;
  if m.nivel >= 35 then t := array_append(t, 'lenda'); end if;
  if m.nivel >= 50 then t := array_append(t, 'mestre'); end if;
  if m.ganho_trabalho >= 1000000 then t := array_append(t, 'milionario'); end if;
  if nc >= 8 and exists (select 1 from casas where dono = m.id and tipo = 'mansao') then t := array_append(t, 'magnata'); end if;
  select coalesce(sum(valor), 0) into gasto from pedidos where morador = m.id and status = 'entregue';
  if gasto >= 300 then t := array_append(t, 'apoiador3'); elsif gasto >= 100 then t := array_append(t, 'apoiador2'); elsif gasto >= 20 then t := array_append(t, 'apoiador1'); end if;
  return t;
end $$;
revoke execute on function public._titulos_de(uuid) from public, anon, authenticated;

create or replace function public.meus_titulos() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  return json_build_object('titulos', _titulos_de(m.id), 'titulo', m.titulo, 'tarefas', m.tarefas_total, 'ganho', m.ganho_trabalho);
end $$;
grant execute on function public.meus_titulos() to authenticated;

create or replace function public.usar_titulo(p_titulo text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_titulo is not null and not (p_titulo = any(_titulos_de(m.id))) then raise exception 'Você ainda não tem esse título.'; end if;
  update moradores set titulo = p_titulo where id = m.id;
  return json_build_object('titulo', p_titulo);
end $$;
grant execute on function public.usar_titulo(text) to authenticated;

create or replace function public.resgatar_codigo(p_codigo text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; c public.codigos;
begin
  m := _eu();
  select * into c from codigos where id = upper(trim(p_codigo)) and ate > now() for update;
  if not found then raise exception 'Código inválido ou vencido.'; end if;
  if c.titulo = any(m.titulos) then raise exception 'Você já tem esse título.'; end if;
  update moradores set titulos = array_append(titulos, c.titulo) where id = m.id;
  update codigos set usos = usos + 1 where id = c.id;
  return json_build_object('titulo', c.titulo);
end $$;
grant execute on function public.resgatar_codigo(text) to authenticated;

-- ===================== ETAPA 42: fotos no Cloudflare (R2) =====================
-- Aceita fotos guardadas no servidor da cidade no Cloudflare (as antigas no Supabase continuam valendo).
create or replace function public.definir_foto(p_foto text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores;
begin
  m := _eu();
  if p_foto is not null and (char_length(p_foto) > 400 or (
       p_foto !~ ('^https://[a-z0-9.-]+/storage/v1/object/public/fotos/' || m.id::text || '/[A-Za-z0-9._-]+(\?v=[0-9]+)?$')
   and p_foto !~ ('^https://vila-tempo-real\.obiellsilva\.workers\.dev/f/' || m.id::text || '/perfil-[0-9]+\.jpg$'))) then
    raise exception 'Foto inválida.';
  end if;
  update moradores set foto = p_foto where id = m.id;
  return _estado(m.id);
end $$;

create or replace function public.postar(p_url text, p_legenda text) returns public.posts
language plpgsql security definer set search_path = public as $$
declare m public.moradores; l text := nullif(btrim(coalesce(p_legenda,'')), ''); r public.posts;
begin
  m := _eu();
  if m.banido then raise exception 'Você foi banido.'; end if;
  if char_length(p_url) > 400 or (
       p_url !~ ('^https://[a-z0-9.-]+/storage/v1/object/public/fotos/' || m.id::text || '/post-[0-9]+\.jpg$')
   and p_url !~ ('^https://vila-tempo-real\.obiellsilva\.workers\.dev/f/' || m.id::text || '/post-[0-9]+\.jpg$')) then
    raise exception 'Foto inválida.'; end if;
  if char_length(l) > 120 then raise exception 'A legenda pode ter até 120 letras.'; end if;
  if (select count(*) from posts where autor = m.id and criado_em > now() - interval '1 day') >= 10 then
    raise exception 'Limite de 10 fotos por dia. Volte amanhã!'; end if;
  insert into posts(autor, url, legenda) values (m.id, p_url, limpar_texto(l)) returning * into r;
  return r;
end $$;
grant execute on function public.postar(text, text) to authenticated;

-- ===================== ETAPA 43: compras pelo Google Play (app) =====================
-- a mesma compra do Google Play nunca é entregue duas vezes
create unique index if not exists pedidos_gp_unico on public.pedidos(mp_id) where mp_id like 'gp:%';

-- ===================== ETAPA 44: admin pode definir o nível de um jogador =====================
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
  elsif p_acao = 'nivel' then
    n := greatest(1, least(50, p_valor::integer));
    update moradores set nivel = n, xp = xp_do_nivel(n) where id = a.id;
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


-- ===================== ETAPA 45: comércios dos jogadores (Lanchonete e Loja de Roupas) =====================
-- O jogador compra o ponto, compra mercadoria no fornecedor, escolhe o preço e recolhe o caixa.
-- Os bonecos da cidade compram sozinhos (conta feita pelo tempo que passou, quando alguém abre a loja).
-- Conta de luz e água semanal: sai do caixa (se faltar, do bolso do dono). Esse dinheiro some do jogo.
create table if not exists public.comercios (
  id integer primary key,
  tipo text not null,                    -- lanchonete | butique
  preco_ponto integer not null,
  nivel_min integer not null,
  despesa integer not null,              -- conta de luz e água por semana
  dono uuid references public.moradores(id) on delete set null,
  nome text,
  caixa integer not null default 0,
  vendas bigint not null default 0,
  atrasos integer not null default 0,
  atualizado timestamptz not null default now(),
  pago_ate timestamptz,
  comprado_em timestamptz
);
create table if not exists public.comercio_catalogo (
  tipo text not null, item text not null, nome text not null,
  custo integer not null, ref integer not null, pmin integer not null, pmax integer not null,
  taxa numeric not null,                 -- vendas por hora para os bonecos, no preço de referência
  fome integer not null default 0, sede integer not null default 0, roupa integer, maxq integer not null,
  primary key (tipo, item)
);
create table if not exists public.comercio_itens (
  comercio integer not null references public.comercios(id) on delete cascade,
  item text not null, qtd integer not null default 0, preco integer not null, sobra numeric not null default 0,
  primary key (comercio, item)
);
alter table public.comercios enable row level security;
alter table public.comercio_catalogo enable row level security;
alter table public.comercio_itens enable row level security;
revoke all on public.comercios, public.comercio_catalogo, public.comercio_itens from anon, authenticated;

insert into public.comercios(id, tipo, preco_ponto, nivel_min, despesa) values
  (1, 'lanchonete', 300000, 20, 8000), (2, 'butique', 350000, 25, 10000)
on conflict (id) do update set tipo = excluded.tipo, preco_ponto = excluded.preco_ponto, nivel_min = excluded.nivel_min, despesa = excluded.despesa;

insert into public.comercio_catalogo(tipo, item, nome, custo, ref, pmin, pmax, taxa, fome, sede, roupa, maxq) values
  ('lanchonete','burger','Hambúrguer da casa', 8, 20, 12, 40, 6, 45, 0, null, 300),
  ('lanchonete','suco','Suco natural', 3, 8, 5, 16, 6, 0, 45, null, 300),
  ('lanchonete','combo','Combo X-Tudo', 14, 32, 20, 60, 3, 70, 30, null, 300),
  ('butique','r24','Jaqueta universitária', 400, 1200, 600, 4000, .1, 0, 0, 24, 40),
  ('butique','r25','Camisa anos 70', 400, 1200, 600, 4000, .1, 0, 0, 25, 40),
  ('butique','r26','Kimono florido', 400, 1200, 600, 4000, .1, 0, 0, 26, 40),
  ('butique','r27','Poncho gaúcho', 400, 1200, 600, 4000, .1, 0, 0, 27, 40),
  ('butique','r28','Camisa com suspensório', 400, 1200, 600, 4000, .1, 0, 0, 28, 40),
  ('butique','r29','Jaqueta bomber', 400, 1200, 600, 4000, .1, 0, 0, 29, 40)
on conflict (tipo, item) do update set nome = excluded.nome, custo = excluded.custo, ref = excluded.ref, pmin = excluded.pmin, pmax = excluded.pmax,
  taxa = excluded.taxa, fome = excluded.fome, sede = excluded.sede, roupa = excluded.roupa, maxq = excluded.maxq;
delete from public.comercio_catalogo where tipo = 'butique' and item not in ('r24','r25','r26','r27','r28','r29');

-- coleção da semana na loja de roupas: 2 modelos por semana (o fornecedor só vende esses)
create or replace function public._colecao(p_t timestamptz default now()) returns text[]
language sql stable as $$
  select array(select 'r' || (24 + ((floor(extract(epoch from p_t) / 604800)::integer * 2 + k) % 6)) from generate_series(0, 1) k)
$$;

-- conta as vendas dos bonecos e as contas semanais desde a última vez
create or replace function public._com_atualiza(p_id integer) returns void
language plpgsql security definer set search_path = public as $$
declare c comercios; h numeric; r record; mult numeric; v numeric; n integer; tot integer := 0; d moradores;
begin
  select * into c from comercios where id = p_id for update;
  if not found or c.dono is null then return; end if;
  h := least(72, greatest(0, extract(epoch from now() - c.atualizado) / 3600));
  if h > 0.01 then
    for r in select i.*, k.taxa, k.ref from comercio_itens i join comercio_catalogo k on k.tipo = c.tipo and k.item = i.item where i.comercio = c.id and i.qtd > 0 loop
      mult := greatest(0.1, least(1.5, 2 - r.preco::numeric / r.ref));
      v := r.sobra + r.taxa * mult * h;
      n := least(r.qtd, floor(v)::integer);
      update comercio_itens set qtd = qtd - n, sobra = case when n = r.qtd then 0 else v - n end where comercio = c.id and item = r.item;
      tot := tot + n * r.preco;
      update comercios set vendas = vendas + n where id = c.id;
    end loop;
    update comercios set caixa = caixa + tot, atualizado = now() where id = c.id;
  end if;
  -- contas da semana
  select * into c from comercios where id = p_id;
  while c.pago_ate is not null and c.pago_ate + interval '7 days' <= now() loop
    if c.caixa >= c.despesa then
      update comercios set caixa = caixa - despesa, pago_ate = pago_ate + interval '7 days', atrasos = 0 where id = c.id;
    else
      select * into d from moradores where id = c.dono for update;
      if d.dinheiro >= c.despesa - greatest(0, c.caixa) then
        update moradores set dinheiro = dinheiro - (c.despesa - greatest(0, c.caixa)) where id = d.id;
        update comercios set caixa = 0, pago_ate = pago_ate + interval '7 days', atrasos = 0 where id = c.id;
      else
        update comercios set pago_ate = pago_ate + interval '7 days', atrasos = atrasos + 1 where id = c.id;
      end if;
    end if;
    select * into c from comercios where id = p_id;
    if c.atrasos >= 2 then -- duas contas sem pagar: o ponto volta à venda
      delete from comercio_itens where comercio = c.id;
      update comercios set dono = null, nome = null, caixa = 0, atrasos = 0, pago_ate = null, comprado_em = null where id = c.id;
      return;
    end if;
  end loop;
end $$;
revoke execute on function public._com_atualiza(integer) from public, anon, authenticated;

create or replace function public._com_json(p_id integer) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', c.id, 'tipo', c.tipo, 'preco_ponto', c.preco_ponto, 'nivel_min', c.nivel_min, 'despesa', c.despesa,
    'dono', c.dono, 'dono_nome', m.nome, 'nome', c.nome,
    'caixa', case when c.dono = auth.uid() then c.caixa end, 'vendas', case when c.dono = auth.uid() then c.vendas end,
    'pago_ate', case when c.dono = auth.uid() then c.pago_ate end, 'atrasos', case when c.dono = auth.uid() then c.atrasos end,
    'colecao', case when c.tipo = 'butique' then _colecao() end,
    'itens', coalesce((select json_agg(json_build_object('item', i.item, 'qtd', i.qtd, 'preco', i.preco) order by i.item) from comercio_itens i where i.comercio = c.id), '[]'::json))
  from comercios c left join moradores m on m.id = c.dono where c.id = p_id
$$;
revoke execute on function public._com_json(integer) from public, anon;

-- lista de todos os comércios (para a fachada e para o painel)
create or replace function public.comercios() returns json
language plpgsql security definer set search_path = public as $$
declare r record;
begin
  for r in select id from comercios where dono is not null and atualizado < now() - interval '2 minutes' loop perform _com_atualiza(r.id); end loop;
  return (select json_agg(_com_json(id) order by id) from comercios);
end $$;
grant execute on function public.comercios() to authenticated;

create or replace function public.comprar_comercio(p_id integer) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; c comercios;
begin
  m := _eu();
  perform _com_atualiza(p_id);
  select * into c from comercios where id = p_id for update;
  if not found then raise exception 'Esse ponto não existe.'; end if;
  if c.dono is not null then raise exception 'Esse ponto já tem dono.'; end if;
  if exists (select 1 from comercios where dono = m.id) then raise exception 'Você já tem um comércio. Um por pessoa!'; end if;
  if m.nivel < c.nivel_min then raise exception 'Libera no nível %.', c.nivel_min; end if;
  if m.dinheiro < c.preco_ponto then raise exception 'Dinheiro insuficiente. O ponto custa R$ %.', c.preco_ponto; end if;
  update moradores set dinheiro = dinheiro - c.preco_ponto where id = m.id;
  delete from comercio_itens where comercio = c.id;
  update comercios set dono = m.id, nome = left(case when c.tipo = 'lanchonete' then 'Lanchonete' else 'Loja' end || ' do ' || split_part(m.nome, ' ', 1), 22),
    caixa = 0, vendas = 0, atrasos = 0, atualizado = now(), pago_ate = now(), comprado_em = now() where id = c.id;
  return json_build_object('comercio', _com_json(c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.comprar_comercio(integer) to authenticated;

create or replace function public._meu_comercio(p_id integer) returns comercios
language plpgsql security definer set search_path = public as $$
declare c comercios;
begin
  perform _com_atualiza(p_id);
  select * into c from comercios where id = p_id for update;
  if not found or c.dono is distinct from auth.uid() then raise exception 'Esse comércio não é seu.'; end if;
  return c;
end $$;
revoke execute on function public._meu_comercio(integer) from public, anon, authenticated;

-- comprar mercadoria no fornecedor
create or replace function public.com_repor(p_id integer, p_item text, p_qtd integer) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; c comercios; k comercio_catalogo; atual integer; custo integer;
begin
  m := _eu(); c := _meu_comercio(p_id);
  select * into k from comercio_catalogo where tipo = c.tipo and item = p_item;
  if not found then raise exception 'Produto inválido.'; end if;
  if c.tipo = 'butique' and not (p_item = any(_colecao())) then raise exception 'Essa roupa saiu de linha. O fornecedor não tem mais.'; end if;
  if p_qtd < 1 or p_qtd > 500 then raise exception 'Quantidade inválida.'; end if;
  select qtd into atual from comercio_itens where comercio = c.id and item = p_item;
  if coalesce(atual, 0) + p_qtd > k.maxq then raise exception 'O estoque cabe no máximo % unidades.', k.maxq; end if;
  custo := k.custo * p_qtd;
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', custo; end if;
  update moradores set dinheiro = dinheiro - custo where id = m.id;
  insert into comercio_itens(comercio, item, qtd, preco) values (c.id, p_item, p_qtd, k.ref)
  on conflict (comercio, item) do update set qtd = comercio_itens.qtd + p_qtd;
  return json_build_object('custo', custo, 'comercio', _com_json(c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.com_repor(integer, text, integer) to authenticated;

create or replace function public.com_preco(p_id integer, p_item text, p_preco integer) returns json
language plpgsql security definer set search_path = public as $$
declare c comercios; k comercio_catalogo;
begin
  c := _meu_comercio(p_id);
  select * into k from comercio_catalogo where tipo = c.tipo and item = p_item;
  if not found then raise exception 'Produto inválido.'; end if;
  if p_preco < k.pmin or p_preco > k.pmax then raise exception 'O preço tem que ficar entre R$ % e R$ %.', k.pmin, k.pmax; end if;
  update comercio_itens set preco = p_preco where comercio = c.id and item = p_item;
  if not found then raise exception 'Compre esse produto no fornecedor primeiro.'; end if;
  return json_build_object('comercio', _com_json(c.id));
end $$;
grant execute on function public.com_preco(integer, text, integer) to authenticated;

create or replace function public.com_recolher(p_id integer) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; c comercios; v integer;
begin
  m := _eu(); c := _meu_comercio(p_id);
  v := greatest(0, c.caixa);
  if v = 0 then raise exception 'O caixa está vazio.'; end if;
  update comercios set caixa = caixa - v where id = c.id;
  update moradores set dinheiro = dinheiro + v where id = m.id;
  return json_build_object('valor', v, 'comercio', _com_json(c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.com_recolher(integer) to authenticated;

create or replace function public.com_nome(p_id integer, p_nome text) returns json
language plpgsql security definer set search_path = public as $$
declare c comercios; n text;
begin
  c := _meu_comercio(p_id);
  n := btrim(regexp_replace(limpar_texto(coalesce(p_nome, '')), '\s+', ' ', 'g'));
  if char_length(n) < 3 or char_length(n) > 22 then raise exception 'O nome tem que ter de 3 a 22 letras.'; end if;
  update comercios set nome = n where id = c.id;
  return json_build_object('comercio', _com_json(c.id));
end $$;
grant execute on function public.com_nome(integer, text) to authenticated;

-- um jogador compra na loja de outro (ou na sua)
create or replace function public.com_comprar(p_id integer, p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; c comercios; i comercio_itens; k comercio_catalogo; morreu boolean := false;
begin
  m := _eu();
  perform _com_atualiza(p_id);
  select * into c from comercios where id = p_id;
  if not found or c.dono is null then raise exception 'Essa loja está fechada.'; end if;
  select * into i from comercio_itens where comercio = c.id and item = p_item for update;
  if not found or i.qtd < 1 then raise exception 'Acabou o estoque desse produto.'; end if;
  select * into k from comercio_catalogo where tipo = c.tipo and item = p_item;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente.'; end if;
  if k.roupa is not null then
    if exists (select 1 from guarda_roupa where morador = m.id and peca = 'roupa_' || case when coalesce((_vis_nums(m.visual))[10], 0) = 1 then 'f' else 'm' end and item = k.roupa) then raise exception 'Você já tem essa roupa. Vista no guarda-roupa!'; end if;
    insert into guarda_roupa(morador, peca, item) values (m.id, 'roupa_m', k.roupa), (m.id, 'roupa_f', k.roupa) on conflict do nothing;
    update moradores set dinheiro = dinheiro - i.preco where id = m.id;
  else
    morreu := _gastar_fome(m.id, 0);
    update moradores set dinheiro = dinheiro - i.preco, fome = least(100, fome + k.fome), sede = least(100, sede + k.sede) where id = m.id;
  end if;
  update comercio_itens set qtd = qtd - 1 where comercio = c.id and item = p_item;
  update comercios set caixa = caixa + i.preco, vendas = vendas + 1 where id = c.id;
  return json_build_object('item', p_item, 'preco', i.preco, 'morreu', morreu, 'comercio', _com_json(c.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.com_comprar(integer, text) to authenticated;

-- a Loja de Roupas oficial não vende as roupas da coleção (24-29): só a loja dos jogadores
create or replace function public.comprar_roupa(p_peca text, p_item integer) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; pr integer;
begin
  m := _eu();
  if p_peca not in ('roupa_m','roupa_f','calca_m','calca_f','calcado_m','calcado_f','chapeu_m','chapeu_f','extra_m','extra_f','estampa') then raise exception 'Peça inválida.'; end if;
  if p_item < 0 or p_item >= 50 then raise exception 'Peça inválida.'; end if;
  if p_item >= 30 and p_item < 40 then raise exception 'Esse item é exclusivo do Passe da Temporada.'; end if;
  if p_peca in ('roupa_m','roupa_f') and p_item between 24 and 29 then raise exception 'Essa roupa só é vendida na loja de roupas dos jogadores.'; end if;
  if exists (select 1 from guarda_roupa where morador = m.id and peca = p_peca and item = p_item) then return json_build_object('ok', true, 'eu', _estado(m.id)); end if;
  pr := preco_roupa(p_peca, p_item);
  if m.dinheiro < pr then raise exception 'Dinheiro insuficiente.'; end if;
  insert into guarda_roupa(morador, peca, item) values (m.id, p_peca, p_item);
  update moradores set dinheiro = dinheiro - pr where id = m.id;
  return json_build_object('ok', true, 'eu', _estado(m.id));
end $$;
grant execute on function public.comprar_roupa(text, integer) to authenticated;

-- ===================== ETAPA 46: hortinha no quintal da casa =====================
-- O dono da casa planta nos canteiros da frente (3 na casa, 4 na mansão). A planta cresce pelo tempo real;
-- quando fica pronta, ele colhe e os legumes vão para a mochila (dá para comer depois).
create table if not exists public.horta_plantas (
  id text primary key, nome text not null, semente integer not null, horas numeric not null, colhe integer not null
);
alter table public.horta_plantas enable row level security;
revoke all on public.horta_plantas from anon, authenticated;
insert into public.horta_plantas(id, nome, semente, horas, colhe) values
  ('alface','Alface',5,2,3),('tomate','Tomate',8,4,4),('cenoura','Cenoura',10,6,4),('morango','Morango',20,8,5),('milho','Milho',15,10,3)
on conflict (id) do update set nome = excluded.nome, semente = excluded.semente, horas = excluded.horas, colhe = excluded.colhe;

-- o que se colhe vira item de comer (não é vendido em loja nenhuma: local 'horta')
insert into public.loja(id, tipo, nome, preco, local, fome, sede, nivel_min) values
  ('h_alface','consumo','um pé de alface',6,'horta',12,2,1),('h_tomate','consumo','um tomate',5,'horta',8,6,1),
  ('h_cenoura','consumo','uma cenoura',6,'horta',14,1,1),('h_morango','consumo','uns morangos',8,'horta',6,8,1),
  ('h_milho','consumo','uma espiga de milho',10,'horta',22,0,1)
on conflict (id) do update set nome = excluded.nome, local = excluded.local, fome = excluded.fome, sede = excluded.sede;

create table if not exists public.hortas (
  casa integer not null references public.casas(id) on delete cascade,
  slot integer not null,
  planta text not null references public.horta_plantas(id),
  plantado_em timestamptz not null default now(),
  primary key (casa, slot)
);
alter table public.hortas enable row level security;
revoke all on public.hortas from anon, authenticated;

-- todo mundo vê as hortas (para desenhar as plantas crescendo nos quintais)
create or replace function public.hortas() returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('agora', now(), 'h', coalesce((select json_agg(json_build_object('casa', casa, 'slot', slot, 'planta', planta, 'em', plantado_em)) from hortas), '[]'::json))
$$;
grant execute on function public.hortas() to authenticated;

create or replace function public._minha_horta(p_casa integer, p_slot integer) returns casas
language plpgsql security definer set search_path = public as $$
declare c casas;
begin
  select * into c from casas where id = p_casa;
  if not found or c.id > 1000 then raise exception 'Essa casa não tem quintal.'; end if;
  if c.dono is distinct from auth.uid() then raise exception 'Só o dono da casa mexe na horta.'; end if;
  if p_slot < 0 or p_slot >= (case when c.preco >= 200000 then 4 else 3 end) then raise exception 'Canteiro inválido.'; end if;
  return c;
end $$;
revoke execute on function public._minha_horta(integer, integer) from public, anon, authenticated;

create or replace function public.plantar(p_casa integer, p_slot integer, p_planta text) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; p horta_plantas;
begin
  m := _eu(); perform _minha_horta(p_casa, p_slot);
  select * into p from horta_plantas where id = p_planta;
  if not found then raise exception 'Semente inválida.'; end if;
  if exists (select 1 from hortas where casa = p_casa and slot = p_slot) then raise exception 'Esse canteiro já está plantado.'; end if;
  if m.dinheiro < p.semente then raise exception 'Dinheiro insuficiente para a semente.'; end if;
  update moradores set dinheiro = dinheiro - p.semente where id = m.id;
  insert into hortas(casa, slot, planta) values (p_casa, p_slot, p_planta);
  return json_build_object('ok', true, 'eu', _estado(m.id));
end $$;
grant execute on function public.plantar(integer, integer, text) to authenticated;

create or replace function public.colher(p_casa integer, p_slot integer) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; h hortas; p horta_plantas; k text; q integer; n integer;
begin
  m := _eu(); perform _minha_horta(p_casa, p_slot);
  select * into h from hortas where casa = p_casa and slot = p_slot for update;
  if not found then raise exception 'Esse canteiro está vazio.'; end if;
  select * into p from horta_plantas where id = h.planta;
  if now() < h.plantado_em + make_interval(secs => (p.horas * 3600)::integer) then raise exception 'Ainda não está pronto. Volte mais tarde! 🌱'; end if;
  k := 'h_' || p.id; q := coalesce((m.mochila->>k)::integer, 0); n := least(20, q + p.colhe);
  delete from hortas where casa = p_casa and slot = p_slot;
  update moradores set mochila = mochila || jsonb_build_object(k, n) where id = m.id;
  return json_build_object('item', k, 'qtd', n - q, 'mochila', (select mochila from moradores where id = m.id), 'eu', _estado(m.id));
end $$;
grant execute on function public.colher(integer, integer) to authenticated;

-- ===================== ETAPA 47: vender a colheita da horta no mercadinho =====================
create or replace function public.vender_horta() returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; k text; q integer; pr integer; tot integer := 0; n integer := 0; mo jsonb;
begin
  m := _eu(); mo := coalesce(m.mochila, '{}'::jsonb);
  for k, pr in select * from (values ('h_alface',4),('h_tomate',4),('h_cenoura',5),('h_morango',7),('h_milho',9)) v(i, p) loop
    q := coalesce((mo->>k)::integer, 0);
    if q > 0 then tot := tot + q * pr; n := n + q; mo := mo - k; end if;
  end loop;
  if n = 0 then raise exception 'Você não tem legumes da horta na mochila.'; end if;
  update moradores set mochila = mo, dinheiro = dinheiro + tot where id = m.id;
  return json_build_object('ganho', tot, 'vendidos', n, 'mochila', mo, 'eu', _estado(m.id));
end $$;
grant execute on function public.vender_horta() to authenticated;

-- ===================== ETAPA 48: casas mais caras (devolução), salários +15%, loja de roupas zerada =====================
-- Pode rodar mais de uma vez: cada ajuste só acontece uma vez (fica anotado na tabela "ajustes").
create table if not exists public.ajustes (id text primary key, feito timestamptz not null default now());
alter table public.ajustes enable row level security;
revoke all on public.ajustes from anon, authenticated;

-- 1) "Tipo" da casa (1 de cada tipo por pessoa): simples < R$ 60.000 <= média < R$ 200.000 <= mansão
drop index if exists public.casas_um_por_tipo;
alter table public.casas drop column if exists tipo;
alter table public.casas add column tipo text generated always as (case when id > 1000 then 'apto' when preco >= 200000 then 'mansao' when preco >= 60000 then 'media' else 'barata' end) stored;

do $$
declare r record; volta integer;
begin
  -- 2) Devolve as casas: o dono recebe o PREÇO NOVO + os móveis pelo preço cheio; a comida da geladeira vai para a mochila
  if not exists (select 1 from ajustes where id = 'casas_2026_11') then
    update casas set preco = case preco when 30000 then 50000 when 45000 then 70000 when 75000 then 90000 when 350000 then 500000 else preco end
      where id < 1000;
    for r in select * from casas where id < 1000 and dono is not null loop
      select coalesce(sum(coalesce(preco_movel(e->>'t'), 0)), 0) into volta from jsonb_array_elements(r.moveis) e;
      update moradores m set dinheiro = m.dinheiro + r.preco + volta,
        mochila = (select coalesce(jsonb_object_agg(k, coalesce((m.mochila->>k)::int, 0) + coalesce((r.geladeira->>k)::int, 0)), '{}'::jsonb)
                   from (select jsonb_object_keys(m.mochila) k union select jsonb_object_keys(r.geladeira)) ks),
        casa_id = case when m.casa_id = r.id then (select a.id from casas a where a.dono = m.id and a.id > 1000 limit 1) else m.casa_id end
        where m.id = r.dono;
      update vagas set morador = null, carro = null, desde = null where casa = r.id;
      if to_regclass('public.hortas') is not null then execute 'delete from public.hortas where casa = $1' using r.id; end if;
      update casas set dono = null, comprada_em = null, aberta = false, moveis = '[]'::jsonb, geladeira = '{}'::jsonb where id = r.id;
    end loop;
    insert into ajustes(id) values ('casas_2026_11');
  end if;

  -- 3) Salários +15% para todos os empregos
  if not exists (select 1 from ajustes where id = 'salarios_15') then
    update trabalhos set salario = round(salario * 1.15);
    insert into ajustes(id) values ('salarios_15');
  end if;

  -- 4) Loja de Roupas da Vila (ponto 2) volta a ficar à venda; o dono recebe de volta o ponto, o caixa e a mercadoria
  if not exists (select 1 from ajustes where id = 'reset_loja_2') then
    for r in select * from comercios where id = 2 and dono is not null loop
      update moradores set dinheiro = dinheiro + r.preco_ponto + r.caixa
        + coalesce((select sum(i.qtd * k.custo) from comercio_itens i join comercio_catalogo k on k.tipo = r.tipo and k.item = i.item where i.comercio = r.id), 0)
        where id = r.dono;
      delete from comercio_itens where comercio = r.id;
      update comercios set dono = null, nome = null, caixa = 0, vendas = 0, atrasos = 0, pago_ate = null, comprado_em = null, atualizado = now() where id = r.id;
    end loop;
    insert into ajustes(id) values ('reset_loja_2');
  end if;
end $$;
create unique index if not exists casas_um_por_tipo on public.casas(dono, tipo) where dono is not null;

-- peixe do pescador +15% (R$ 28 -> R$ 32)
create or replace function public.vender_peixes() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer;
begin
  m := _eu();
  if m.peixes < 1 then raise exception 'Você não tem peixe para vender.'; end if;
  ganho := m.peixes * 32;
  update moradores set dinheiro = dinheiro + ganho, peixes = 0 where id = m.id;
  return json_build_object('ganho', ganho, 'vendidos', m.peixes, 'eu', _estado(m.id));
end $$;

-- ronda da polícia +15% (R$ 50 -> R$ 58)
create or replace function public.ronda_policia() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; novo_xp integer; novo_nivel integer; premio integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is distinct from 'policia' then raise exception 'Você não está de patrulha.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '85 seconds' then
    raise exception 'O próximo pagamento da patrulha ainda não chegou.';
  end if;
  novo_xp := m.xp + 20;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + 58 + premio, xp = novo_xp, nivel = novo_nivel, tarefa_em = now() where id = m.id;
  perform _passe_pontos(m.id, 15);
  morreu := _gastar_fome(m.id, 1);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', 58, 'xp_ganho', 20, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;


-- ===== ETAPA 49: comércios mais caros (quem já é dono continua) =====
update public.comercios set preco_ponto = 300000, nivel_min = 20, despesa = 8000 where id = 1;
update public.comercios set preco_ponto = 350000, nivel_min = 25, despesa = 10000 where id = 2;

-- ===== ETAPA 50: eleição do prefeito (sexta candidatura, sábado votação, domingo 2º turno se empatar) =====
create table if not exists public.eleicao_cand (
  semana date not null, morador uuid not null references public.moradores(id) on delete cascade,
  msg text not null default '', criado timestamptz not null default now(), primary key (semana, morador));
create table if not exists public.eleicao_votos (
  semana date not null, turno integer not null, eleitor uuid not null references public.moradores(id) on delete cascade,
  cand uuid not null, votado timestamptz not null default now(), primary key (semana, turno, eleitor));
create table if not exists public.eleicao_res (
  semana date not null, turno integer not null, vencedor uuid, empatados uuid[], votos json, apurado timestamptz not null default now(),
  primary key (semana, turno));
alter table public.eleicao_cand enable row level security;
alter table public.eleicao_votos enable row level security;
alter table public.eleicao_res enable row level security;
revoke all on public.eleicao_cand, public.eleicao_votos, public.eleicao_res from anon, authenticated;

-- dia de hoje no horário de Brasília
create or replace function public._hoje_br() returns date language sql stable as $$ select (now() at time zone 'America/Sao_Paulo')::date $$;

-- apura o que já fechou (roda sozinho quando alguém abre a eleição; não precisa de agendador)
create or replace function public._eleicao_apura() returns void
language plpgsql security definer set search_path = public as $$
declare h date := _hoje_br(); s date; mx integer; emp uuid[]; w uuid; v json; r record;
begin
  s := h - ((extract(dow from h)::int + 2) % 7);           -- sexta-feira desta semana (ou a última)
  if h < s + 2 then s := s - 7; end if;                    -- antes de domingo: a última apuração possível é da semana passada
  -- 1º turno (fecha no domingo 00h)
  if not exists (select 1 from eleicao_res where semana = s and turno = 1) then
    select coalesce(json_agg(json_build_object('id', c.morador, 'votos', coalesce(n.q, 0)) order by coalesce(n.q,0) desc, c.criado), '[]'),
           max(coalesce(n.q, 0)) into v, mx
      from eleicao_cand c left join (select cand, count(*) q from eleicao_votos where semana = s and turno = 1 group by cand) n on n.cand = c.morador
     where c.semana = s;
    if coalesce(mx, 0) = 0 then                            -- ninguém se candidatou ou ninguém votou: prefeito atual continua
      insert into eleicao_res(semana, turno, vencedor, votos) values (s, 1, null, v) on conflict do nothing;
    else
      select array_agg(c.morador order by c.criado) into emp from eleicao_cand c
       where c.semana = s and (select count(*) from eleicao_votos where semana = s and turno = 1 and cand = c.morador) = mx;
      if array_length(emp, 1) = 1 then
        insert into eleicao_res(semana, turno, vencedor, votos) values (s, 1, emp[1], v) on conflict do nothing;
        update cidade set prefeito = emp[1], desde = now() where id = 1;
      else
        insert into eleicao_res(semana, turno, vencedor, empatados, votos) values (s, 1, null, emp, v) on conflict do nothing;
      end if;
    end if;
  end if;
  -- 2º turno (domingo; fecha na segunda 00h). Empate de novo: ganha quem se candidatou primeiro.
  select * into r from eleicao_res where semana = s and turno = 1;
  if r.empatados is not null and h >= s + 3 and not exists (select 1 from eleicao_res where semana = s and turno = 2) then
    select json_agg(json_build_object('id', c.morador, 'votos', coalesce(n.q, 0)) order by coalesce(n.q,0) desc, c.criado),
           (array_agg(c.morador order by coalesce(n.q,0) desc, c.criado))[1] into v, w
      from eleicao_cand c left join (select cand, count(*) q from eleicao_votos where semana = s and turno = 2 group by cand) n on n.cand = c.morador
     where c.semana = s and c.morador = any(r.empatados);
    insert into eleicao_res(semana, turno, vencedor, votos) values (s, 2, w, v) on conflict do nothing;
    update cidade set prefeito = w, desde = now() where id = 1;
  end if;
end $$;
revoke execute on function public._eleicao_apura() from anon, authenticated, public;

-- situação da eleição para o jogo (votos ficam escondidos até a apuração)
create or replace function public.eleicao() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; h date := _hoje_br(); d int; s date; fase text := 'fechada'; tn int := 0; r1 public.eleicao_res;
  cands json; ult json; voto uuid; souc boolean; pode boolean; motivo text;
begin
  m := _eu(); perform _eleicao_apura();
  d := extract(dow from h)::int; s := h - ((d + 2) % 7);
  select * into r1 from eleicao_res where semana = s and turno = 1;
  if d = 5 then fase := 'candidatura';
  elsif d = 6 then fase := 'votacao'; tn := 1;
  elsif d = 0 and r1.empatados is not null then fase := 'segundo'; tn := 2; end if;
  select coalesce(json_agg(json_build_object('id', c.morador, 'nome', mo.nome, 'nivel', mo.nivel, 'foto', mo.foto, 'vis', mo.visual, 'msg', c.msg) order by c.criado), '[]')
    into cands from eleicao_cand c join moradores mo on mo.id = c.morador
   where c.semana = s and not coalesce(mo.banido, false) and (tn <> 2 or c.morador = any(r1.empatados));
  souc := exists (select 1 from eleicao_cand where semana = s and morador = m.id);
  select cand into voto from eleicao_votos where semana = s and eleicao_votos.turno = tn and eleitor = m.id;
  motivo := case when tn = 0 then 'A votação é no sábado.' when souc then 'Candidato não vota.' when m.nivel < 5 then 'Para votar precisa ser nível 5.' end;
  pode := motivo is null;
  select json_build_object('semana', x.semana, 'turno', x.turno, 'vencedor', x.vencedor, 'vencedor_nome', (select nome from moradores where id = x.vencedor),
         'empatados', x.empatados,
         'votos', (select json_agg(json_build_object('nome', mo.nome, 'votos', (e->>'votos')::int)) from json_array_elements(x.votos) e join moradores mo on mo.id = (e->>'id')::uuid))
    into ult from eleicao_res x order by x.semana desc, x.turno desc limit 1;
  return json_build_object('fase', fase, 'turno', tn, 'semana', s, 'candidatos', cands, 'sou_candidato', souc, 'pode_votar', pode,
    'motivo', motivo, 'meu_voto', voto, 'pode_candidatar', fase = 'candidatura' and m.nivel >= 20 and not souc, 'resultado', ult);
end $$;
grant execute on function public.eleicao() to authenticated;

create or replace function public.candidatar(p_msg text) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; h date := _hoje_br();
begin
  m := _eu();
  if extract(dow from h) <> 5 then raise exception 'A candidatura é só na sexta-feira.'; end if;
  if m.nivel < 20 then raise exception 'Para se candidatar precisa ser nível 20.'; end if;
  if char_length(coalesce(trim(p_msg), '')) < 3 then raise exception 'Escreva sua mensagem para os eleitores.'; end if;
  insert into eleicao_cand(semana, morador, msg) values (h, m.id, left(trim(p_msg), 160))
  on conflict (semana, morador) do update set msg = excluded.msg;
  delete from eleicao_votos where semana = h and eleitor = m.id;
  return eleicao();
end $$;
grant execute on function public.candidatar(text) to authenticated;

create or replace function public.votar(p_cand uuid) returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; e json;
begin
  m := _eu(); e := eleicao();
  if (e->>'turno')::int = 0 then raise exception 'A votação é no sábado.'; end if;
  if not (e->>'pode_votar')::boolean then raise exception '%', e->>'motivo'; end if;
  if e->>'meu_voto' is not null then raise exception 'Você já votou.'; end if;
  if not exists (select 1 from json_array_elements(e->'candidatos') c where (c->>'id')::uuid = p_cand) then raise exception 'Esse candidato não está na eleição.'; end if;
  insert into eleicao_votos(semana, turno, eleitor, cand) values ((e->>'semana')::date, (e->>'turno')::int, m.id, p_cand);
  return eleicao();
end $$;
grant execute on function public.votar(uuid) to authenticated;

-- prefeito agora só pela eleição
create or replace function public.assumir_prefeitura() returns json
language plpgsql security definer set search_path = public as $$
begin raise exception 'Agora o prefeito é escolhido na eleição: candidatura na sexta, votação no sábado.'; end $$;

-- ===== ETAPA 51: salários +30% (roda uma vez só) e peixe +30% (R$ 32 -> R$ 42) =====
do $$ begin
  if not exists (select 1 from ajustes where id = 'salarios_30') then
    update trabalhos set salario = round(salario * 1.3);
    insert into ajustes(id) values ('salarios_30');
  end if;
end $$;
create or replace function public.vender_peixes() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; ganho integer;
begin
  m := _eu();
  if m.peixes < 1 then raise exception 'Você não tem peixe para vender.'; end if;
  ganho := m.peixes * 42;
  update moradores set dinheiro = dinheiro + ganho, peixes = 0 where id = m.id;
  return json_build_object('ganho', ganho, 'vendidos', m.peixes, 'eu', _estado(m.id));
end $$;

-- ronda da polícia +30% (R$ 58 -> R$ 75)
create or replace function public.ronda_policia() returns json
language plpgsql security definer set search_path = public as $$
declare m public.moradores; novo_xp integer; novo_nivel integer; premio integer := 0; morreu boolean; cansado boolean := false;
begin
  m := _eu();
  if m.trabalho is distinct from 'policia' then raise exception 'Você não está de patrulha.'; end if;
  if m.tarefa_em is not null and now() - m.tarefa_em < interval '85 seconds' then
    raise exception 'O próximo pagamento da patrulha ainda não chegou.';
  end if;
  novo_xp := m.xp + 20;
  novo_nivel := nivel_de(novo_xp);
  if novo_nivel > m.nivel then
    select coalesce(sum(50 * g), 0) into premio from generate_series(m.nivel + 1, novo_nivel) g;
  end if;
  update moradores set dinheiro = dinheiro + 75 + premio, xp = novo_xp, nivel = novo_nivel, tarefa_em = now() where id = m.id;
  perform _passe_pontos(m.id, 15);
  morreu := _gastar_fome(m.id, 1);
  if morreu or (select fome from moradores where id = m.id) < 10 then
    cansado := true;
    update moradores set trabalho = null, trabalho_inicio = null, turnos = turnos + 1 where id = m.id;
  end if;
  return json_build_object('pago', 75, 'xp_ganho', 20, 'subiu', novo_nivel - m.nivel, 'premio', premio,
    'morreu', morreu, 'cansado', cansado, 'eu', _estado(m.id));
end $$;

-- ===== ETAPA 52: quiosques da praça (pipoca, açaí, pastel/caldo de cana, banca) + painel de lucros =====
-- Pontos de R$ 30 a 50 mil ( nível 8, conta R$ 200/semana). O lucro é por produto: paga o custo no fornecedor e vende pelo preço que escolher.
alter table public.comercios add column if not exists investido bigint not null default 0;   -- gasto com mercadoria
alter table public.comercios add column if not exists faturado bigint not null default 0;    -- tudo o que foi vendido
alter table public.comercios add column if not exists contas bigint not null default 0;      -- contas de luz e água pagas
insert into public.comercios(id, tipo, preco_ponto, nivel_min, despesa) values
  (3, 'pipoca', 30000, 8, 200), (4, 'acai', 50000, 8, 200), (5, 'caldo', 40000, 8, 200), (6, 'banca', 30000, 8, 200)
on conflict (id) do update set tipo = excluded.tipo, preco_ponto = excluded.preco_ponto, nivel_min = excluded.nivel_min, despesa = excluded.despesa;
insert into public.comercio_catalogo(tipo, item, nome, custo, ref, pmin, pmax, taxa, fome, sede, roupa, maxq) values
  ('pipoca','salgada','Pipoca salgada', 10, 25, 15, 50, .07, 15, 0, null, 60),
  ('pipoca','doce','Pipoca doce', 12, 28, 16, 55, .07, 15, 0, null, 60),
  ('pipoca','algodao','Algodão-doce', 15, 35, 20, 70, .06, 10, 0, null, 60),
  ('acai','acai','Açaí 300 ml', 20, 45, 28, 90, .07, 25, 10, null, 60),
  ('acai','casquinha','Sorvete de casquinha', 8, 20, 12, 40, .07, 5, 15, null, 60),
  ('acai','picole','Picolé', 5, 12, 7, 25, .07, 0, 15, null, 60),
  ('caldo','caldo','Caldo de cana', 8, 20, 12, 40, .07, 0, 40, null, 60),
  ('caldo','pastelc','Pastel de carne', 12, 28, 16, 55, .07, 35, 0, null, 60),
  ('caldo','pastelq','Pastel de queijo', 12, 28, 16, 55, .07, 35, 0, null, 60),
  ('banca','revista','Revista da semana', 10, 25, 15, 50, .06, 0, 0, null, 60),
  ('banca','figurinha','Pacote de figurinhas', 6, 15, 9, 30, .08, 0, 0, null, 60),
  ('banca','bala','Bala e chiclete', 2, 6, 3, 12, .08, 3, 0, null, 60)
on conflict (tipo, item) do update set nome = excluded.nome, custo = excluded.custo, ref = excluded.ref, pmin = excluded.pmin, pmax = excluded.pmax,
  taxa = excluded.taxa, fome = excluded.fome, sede = excluded.sede, roupa = excluded.roupa, maxq = excluded.maxq;

-- ETAPA 52 (continuação): contas do painel de lucros
create or replace function public._com_atualiza(p_id integer) returns void
language plpgsql security definer set search_path = public as $$
declare c comercios; h numeric; r record; mult numeric; v numeric; n integer; tot integer := 0; d moradores;
begin
  select * into c from comercios where id = p_id for update;
  if not found or c.dono is null then return; end if;
  h := least(72, greatest(0, extract(epoch from now() - c.atualizado) / 3600));
  if h > 0.01 then
    for r in select i.*, k.taxa, k.ref from comercio_itens i join comercio_catalogo k on k.tipo = c.tipo and k.item = i.item where i.comercio = c.id and i.qtd > 0 loop
      mult := greatest(0.1, least(1.5, 2 - r.preco::numeric / r.ref));
      v := r.sobra + r.taxa * mult * h;
      n := least(r.qtd, floor(v)::integer);
      update comercio_itens set qtd = qtd - n, sobra = case when n = r.qtd then 0 else v - n end where comercio = c.id and item = r.item;
      tot := tot + n * r.preco;
      update comercios set vendas = vendas + n where id = c.id;
    end loop;
    update comercios set caixa = caixa + tot, faturado = faturado + tot, atualizado = now() where id = c.id;
  end if;
  -- contas da semana
  select * into c from comercios where id = p_id;
  while c.pago_ate is not null and c.pago_ate + interval '7 days' <= now() loop
    if c.caixa >= c.despesa then
      update comercios set caixa = caixa - despesa, contas = contas + despesa, pago_ate = pago_ate + interval '7 days', atrasos = 0 where id = c.id;
    else
      select * into d from moradores where id = c.dono for update;
      if d.dinheiro >= c.despesa - greatest(0, c.caixa) then
        update moradores set dinheiro = dinheiro - (c.despesa - greatest(0, c.caixa)) where id = d.id;
        update comercios set caixa = 0, contas = contas + despesa, pago_ate = pago_ate + interval '7 days', atrasos = 0 where id = c.id;
      else
        update comercios set pago_ate = pago_ate + interval '7 days', atrasos = atrasos + 1 where id = c.id;
      end if;
    end if;
    select * into c from comercios where id = p_id;
    if c.atrasos >= 2 then -- duas contas sem pagar: o ponto volta à venda
      delete from comercio_itens where comercio = c.id;
      update comercios set dono = null, nome = null, caixa = 0, atrasos = 0, pago_ate = null, comprado_em = null where id = c.id;
      return;
    end if;
  end loop;
end $$;

create or replace function public._com_json(p_id integer) returns json
language sql stable security definer set search_path = public as $$
  select json_build_object('id', c.id, 'tipo', c.tipo, 'preco_ponto', c.preco_ponto, 'nivel_min', c.nivel_min, 'despesa', c.despesa,
    'dono', c.dono, 'dono_nome', m.nome, 'nome', c.nome,
    'caixa', case when c.dono = auth.uid() then c.caixa end, 'vendas', case when c.dono = auth.uid() then c.vendas end,
    'pago_ate', case when c.dono = auth.uid() then c.pago_ate end,
    'investido', case when c.dono = auth.uid() then c.investido end, 'faturado', case when c.dono = auth.uid() then c.faturado end, 'contas', case when c.dono = auth.uid() then c.contas end,
    'estoque_valor', case when c.dono = auth.uid() then (select coalesce(sum(i.qtd * k.custo), 0) from comercio_itens i join comercio_catalogo k on k.tipo = c.tipo and k.item = i.item where i.comercio = c.id) end, 'atrasos', case when c.dono = auth.uid() then c.atrasos end,
    'colecao', case when c.tipo = 'butique' then _colecao() end,
    'itens', coalesce((select json_agg(json_build_object('item', i.item, 'qtd', i.qtd, 'preco', i.preco) order by i.item) from comercio_itens i where i.comercio = c.id), '[]'::json))
  from comercios c left join moradores m on m.id = c.dono where c.id = p_id
$$;

-- ETAPA 52 (continuação): compra do ponto, fornecedor e venda contam no painel
create or replace function public.comprar_comercio(p_id integer) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; c comercios;
begin
  m := _eu();
  perform _com_atualiza(p_id);
  select * into c from comercios where id = p_id for update;
  if not found then raise exception 'Esse ponto não existe.'; end if;
  if c.dono is not null then raise exception 'Esse ponto já tem dono.'; end if;
  if exists (select 1 from comercios where dono = m.id) then raise exception 'Você já tem um comércio. Um por pessoa!'; end if;
  if m.nivel < c.nivel_min then raise exception 'Libera no nível %.', c.nivel_min; end if;
  if m.dinheiro < c.preco_ponto then raise exception 'Dinheiro insuficiente. O ponto custa R$ %.', c.preco_ponto; end if;
  update moradores set dinheiro = dinheiro - c.preco_ponto where id = m.id;
  delete from comercio_itens where comercio = c.id;
  update comercios set dono = m.id, nome = left(case c.tipo when 'lanchonete' then 'Lanchonete' when 'butique' then 'Loja' when 'pipoca' then 'Pipoca' when 'acai' then 'Açaí' when 'caldo' then 'Pastel' else 'Banca' end || ' do ' || split_part(m.nome, ' ', 1), 22),
    caixa = 0, vendas = 0, atrasos = 0, investido = 0, faturado = 0, contas = 0, atualizado = now(), pago_ate = now(), comprado_em = now() where id = c.id;
  return json_build_object('comercio', _com_json(c.id), 'eu', _estado(m.id));
end $$;

create or replace function public.com_repor(p_id integer, p_item text, p_qtd integer) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; c comercios; k comercio_catalogo; atual integer; custo integer;
begin
  m := _eu(); c := _meu_comercio(p_id);
  select * into k from comercio_catalogo where tipo = c.tipo and item = p_item;
  if not found then raise exception 'Produto inválido.'; end if;
  if c.tipo = 'butique' and not (p_item = any(_colecao())) then raise exception 'Essa roupa saiu de linha. O fornecedor não tem mais.'; end if;
  if p_qtd < 1 or p_qtd > 500 then raise exception 'Quantidade inválida.'; end if;
  select qtd into atual from comercio_itens where comercio = c.id and item = p_item;
  if coalesce(atual, 0) + p_qtd > k.maxq then raise exception 'O estoque cabe no máximo % unidades.', k.maxq; end if;
  custo := k.custo * p_qtd;
  if m.dinheiro < custo then raise exception 'Dinheiro insuficiente. Precisa de R$ %.', custo; end if;
  update moradores set dinheiro = dinheiro - custo where id = m.id;
  update comercios set investido = investido + custo where id = c.id;
  insert into comercio_itens(comercio, item, qtd, preco) values (c.id, p_item, p_qtd, k.ref)
  on conflict (comercio, item) do update set qtd = comercio_itens.qtd + p_qtd;
  return json_build_object('custo', custo, 'comercio', _com_json(c.id), 'eu', _estado(m.id));
end $$;

create or replace function public.com_comprar(p_id integer, p_item text) returns json
language plpgsql security definer set search_path = public as $$
declare m moradores; c comercios; i comercio_itens; k comercio_catalogo; morreu boolean := false;
begin
  m := _eu();
  perform _com_atualiza(p_id);
  select * into c from comercios where id = p_id;
  if not found or c.dono is null then raise exception 'Essa loja está fechada.'; end if;
  select * into i from comercio_itens where comercio = c.id and item = p_item for update;
  if not found or i.qtd < 1 then raise exception 'Acabou o estoque desse produto.'; end if;
  select * into k from comercio_catalogo where tipo = c.tipo and item = p_item;
  if m.dinheiro < i.preco then raise exception 'Dinheiro insuficiente.'; end if;
  if k.roupa is not null then
    if exists (select 1 from guarda_roupa where morador = m.id and peca = 'roupa_' || case when coalesce((_vis_nums(m.visual))[10], 0) = 1 then 'f' else 'm' end and item = k.roupa) then raise exception 'Você já tem essa roupa. Vista no guarda-roupa!'; end if;
    insert into guarda_roupa(morador, peca, item) values (m.id, 'roupa_m', k.roupa), (m.id, 'roupa_f', k.roupa) on conflict do nothing;
    update moradores set dinheiro = dinheiro - i.preco where id = m.id;
  else
    morreu := _gastar_fome(m.id, 0);
    update moradores set dinheiro = dinheiro - i.preco, fome = least(100, fome + k.fome), sede = least(100, sede + k.sede) where id = m.id;
  end if;
  update comercio_itens set qtd = qtd - 1 where comercio = c.id and item = p_item;
  update comercios set caixa = caixa + i.preco, faturado = faturado + i.preco, vendas = vendas + 1 where id = c.id;
  return json_build_object('item', p_item, 'preco', i.preco, 'morreu', morreu, 'comercio', _com_json(c.id), 'eu', _estado(m.id));
end $$;
