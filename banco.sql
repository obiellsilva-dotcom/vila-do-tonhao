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
create unique index if not exists casas_um_dono on public.casas(dono) where dono is not null;

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
  select * into antiga from casas where dono = m.id for update;
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
  ganho := greatest(1, round(t.xp / 20.0 * (1 + 0.04 * extra)));  -- XP reduzido (era /6)
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
