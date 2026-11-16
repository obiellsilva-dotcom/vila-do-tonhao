-- banco- 1 de 16. Rode na ordem.
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
