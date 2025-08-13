create or replace PROCEDURE prc_gera_tabela_pivot_contas_incidencia_dinamica (
    in_seq_execucao IN NUMBER
)
IS
    aux_contas clob;
    aux_contas_select clob;
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
        
        select listagg(distinct case when conta <> -1 then 'nvl("Conta: ' || conta || '", 0) as "Conta: ' || conta || '"' else 'nvl("Total", 0) as "Total"' end, ', ') within group (order by conta desc)
        INTO   aux_contas_select
        from table(PKG_RELATORIOS_PAD_DEV.con_incidencias_analitica(in_seq_execucao));

        execute immediate '
        create table tmp_consulta_incidencias_analiticas as
        select periodo,
        cpf,
        matricula,
        nome,
        tipofolha,
        ' || aux_contas_select || '
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