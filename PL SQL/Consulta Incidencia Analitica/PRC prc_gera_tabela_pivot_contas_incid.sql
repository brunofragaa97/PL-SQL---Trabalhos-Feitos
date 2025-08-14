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
        
        /*select listagg(distinct case when conta <> -1 then 'round(nvl("Conta: ' || conta || '", 0), 2) as "Conta: ' || conta || '"' else 'round(nvl("Total", 0), 2) as "Total"' end, ', ') within group (order by conta desc)
        INTO   aux_contas_select
        from table(PKG_RELATORIOS_PAD_DEV.con_incidencias_analitica(in_seq_execucao));*/
        
        for conta in (
            select distinct conta 
            from table(PKG_RELATORIOS_PAD_DEV.con_incidencias_analitica(in_seq_execucao))
            order by conta desc
        ) loop
            if conta.conta >= 0 then 
                aux_contas_select := case 
                    when aux_contas_select is null then 'round(nvl("Conta: ' || conta.conta || '", 0), 2) as "Conta: ' || conta.conta || ':n.2"'
                    else aux_contas_select || ', round(nvl("Conta: ' || conta.conta || '", 0), 2) as "Conta: ' || conta.conta || ':n.2"'
                end;
            else 
                aux_contas_select := aux_contas_select || ', round(nvl("Total", 0), 2) as "Total:n.2"';
            end if;
        end loop;

        EXECUTE IMMEDIATE '
    CREATE TABLE tmp_consulta_incidencias_analiticas 
    AS
    SELECT 
           periodo,
           cpf,
           REPLACE(matricula, ''.'', '''') AS matricula,
           nome,
           tipofolha,
           ' || aux_contas_select || '
    FROM (
        SELECT *
        FROM TABLE (
            PKG_RELATORIOS_PAD_DEV.con_incidencias_analitica(' || in_seq_execucao || ')
        )
    ) PIVOT (
        SUM(VALOR)
        FOR conta IN (
            ' || aux_contas || '
        )
    )
';
    END;