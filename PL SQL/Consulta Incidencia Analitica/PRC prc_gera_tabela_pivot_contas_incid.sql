--PRC prc_gera_tabela_pivot_contas_incidencia_dinamica 
create or replace PROCEDURE prc_gera_tabela_pivot_contas_incidencia_dinamica (
    in_seq_execucao IN NUMBER
)
IS
    aux_contas varchar2(4000);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'drop table tmp_consulta_incidencias_analiticas';
        EXCEPTION WHEN OTHERS THEN
            IF SQLCODE <> -942 THEN
                RAISE;
            END IF;
        END;
        
        select listagg (distinct conta || case when conta <> -1 then ' as "Conta: ' || conta || '"' else ' as "Total"' end, ', ') within group (order by conta desc)
        INTO   aux_contas 
        from table(PKG_RELATORIOS_PAD_DEV.con_incidencias_analitica(in_seq_execucao));
        
        execute immediate '
        create table tmp_consulta_incidencias_analiticas as
        select *
        from (
            select *
            from table (PKG_RELATORIOS_PAD_DEV.con_incidencias_analitica(' || in_seq_execucao || '))
        ) pivot (
            sum(NVL(valor, 0))
            for conta in (
                ' || aux_contas || '
                )
            )
        ';
    END;