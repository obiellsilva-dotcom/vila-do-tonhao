-- Novidades: cargo de prefeito. Rode no Supabase.
-- ETAPA 10: prefeito da cidade =====================
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
