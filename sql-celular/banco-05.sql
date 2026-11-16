-- banco- 5 de 16. Rode na ordem.
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

