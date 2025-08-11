	--TIPO PKG FUNÇÃI PIPELINED
    
    type tp_rec_con_incidencias_analitica is record(
    periodo     DATE,
    cpf         VARCHAR2(20), -- mudou para string, pois faz regexp_replace
    matricula   NUMBER,
    nome        VARCHAR2(256),
    tipofolha   NUMBER,
    conta       NUMBER,
    valor       NUMBER
);
	
	type tp_tab_con_incidencias_analitica is table of tp_rec_con_incidencias_analitica;
         
	function con_incidencias_analitica(
		in_seq_execucao number
	) return tp_tab_con_incidencias_analitica pipelined;
         
 END PKG_RELATORIOS_PAD_DEV;


 --BODY DA PKG
 FUNCTION con_incidencias_analitica(
		in_seq_execucao NUMBER
    ) RETURN tp_tab_con_incidencias_analitica PIPELINED
    IS
        -- Tipos compatíveis com o retorno das funções e uso posterior
        filtro_referencia_ini DATE;
        filtro_referencia_fim DATE;
        filtro_tipofolha  xcp_array_number_tp := xcp_array_number_tp(); 
        filtro_tipofolha_size number;
        filtro_vinculos xcp_array_number_tp := xcp_array_number_tp();
        filtro_vinculos_size number;
        filtro_incidencia  number;
        
        v_row tp_rec_con_incidencias_analitica;
    BEGIN
    
        -- Se for uma execução teste, aplica valores fixos
        IF in_seq_execucao = 0 THEN
            filtro_referencia_ini := TO_DATE('01/05/2025', 'DD/MM/YYYY');
            filtro_referencia_fim := TO_DATE('31/05/2025', 'DD/MM/YYYY');
            filtro_tipofolha := xcp_array_number_tp(1);
            filtro_incidencia := 110;
        ELSE
            filtro_tipofolha := pkg_xcp_execucao.busca_vlr_par_multi(in_seq_execucao, 'par_tpfolha');
            filtro_vinculos  := pkg_xcp_execucao.busca_vlr_par_multi(in_seq_execucao, 'par_vinculos');
            filtro_incidencia := pkg_xcp_execucao.busca_vlr_par(in_seq_execucao, 'par_incidencia');
    
            pkg_xcp_execucao.busca_dta_intervalo(
                in_seq_execucao, 'par_data',
                filtro_referencia_ini, filtro_referencia_fim
            );
        END IF;
        
        filtro_tipofolha_size := filtro_tipofolha.count;
        filtro_vinculos_size := filtro_vinculos.count;
    
        FOR r IN (
            SELECT p.referencia AS periodo, -- já tipo date
           REGEXP_REPLACE(TO_CHAR(f.cpf), '[^0-9]', '') AS cpf,
           f.matricula,
           f.nome,
           c.tipofolha,
           c.conta,
           c.valor,
           c.valor as total
            FROM funcionarios f
            JOIN calculos c 
				ON f.empresa = c.empresa 
				AND f.matricula = c.matricula
            JOIN periodos p 
				ON c.referencia = p.referencia 
				AND c.tipofolha = p.tipofolha
            JOIN incidencia i 
				ON c.conta = i.conta
            WHERE 0 = 0
			AND p.referencia BETWEEN filtro_referencia_ini AND filtro_referencia_fim
            AND (filtro_tipofolha_size = 0 OR  c.tipofolha MEMBER OF filtro_tipofolha)
            AND (filtro_incidencia IS NULL OR i.tipoincidencia = filtro_incidencia)
            AND (filtro_vinculos_size = 0 OR f.vinculo MEMBER OF filtro_vinculos)
        )
        LOOP
            v_row.periodo    := r.periodo;
            v_row.cpf        := r.cpf;
            v_row.matricula  := r.matricula;
            v_row.nome       := r.nome;
            v_row.tipofolha := r.tipofolha;
            v_row.conta      := r.conta;
            v_row.valor      := r.valor;
    
            PIPE ROW(v_row);
            
            v_row.conta      := -1;
            v_row.valor      := r.valor;
            
            PIPE ROW(v_row);
        END LOOP;
    END;

