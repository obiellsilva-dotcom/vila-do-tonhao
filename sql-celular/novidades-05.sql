-- novidades- 5 de 5. Rode na ordem.
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

