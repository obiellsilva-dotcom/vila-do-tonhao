-- banco- 16 de 16. Rode na ordem.
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

