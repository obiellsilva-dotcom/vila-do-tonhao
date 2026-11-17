-- ETAPA 28, parte 2 de 9. Rode em ordem (1, 2, 3...). Se pedir, toque no botão verde.
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
