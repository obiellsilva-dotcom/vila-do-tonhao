-- ETAPA 28, parte 1 de 9. Rode em ordem (1, 2, 3...). Se pedir, toque no botão verde.
-- Novidades: só a ETAPA 28 (Passe, VIP, guarda-roupa, bônus/multa nas tarefas e sinuca). As etapas 21 a 27 já foram rodadas.

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
