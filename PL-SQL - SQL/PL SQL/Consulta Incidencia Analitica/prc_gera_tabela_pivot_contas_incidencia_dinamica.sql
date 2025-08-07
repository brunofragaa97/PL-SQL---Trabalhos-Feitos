PRC ORIGINAL

create or replace PROCEDURE prc_gera_tabela_pivot_contas_incidencia_dinamica (
/*******************************************************************************************************************
 * Descrição resumida da procedure prc_gera_tabela_pivot_contas_incidencia_dinamica                                        *
 *                                                                                                                                                                         *               
 *        Esta procedure gera uma tabela temporária que consolida dados financeiros de funcionários,                  *
 *        transformando dinamicamente linhas de contas em colunas por meio de SQL dinâmico e PIVOT. Ela:      *
 *        - Apaga a tabela temporária anterior, se existir;                                                                                        *
 *        - Consulta as contas distintas no período e filtros informados;                                                                 *
 *        - Monta dinamicamente a cláusula PIVOT com essas contas como colunas;                                              *
 *        - Cria a tabela temporária com os valores pivotados, substituindo valores nulos por zero.                        *
 *                                                                                                                                                                         *
 *       O resultado é uma tabela organizada para facilitar análises financeiras com colunas dinâmicas                 *
 *       conforme as  contas existentes.                                                                                                                  *
 *                                                                                                                                                                         *
 *   ---> Consulta Incidencias Analiticas / OBJETO: ConsultaIncidenciaAnalitica                                                    *
 *   ---> Tabela:  tmp_consulta_incidencias_analiticas                                                                                            *
 *                                                                                                                                                                          *
 ******************************************************************************************************************/

    -- Parâmetros de entrada
    par_data_ini            DATE,
    par_data_fim           DATE,
    par_tipofolha          NUMBER,
    par_tipoincidencia   NUMBER
)
IS
    -- Tipo para armazenar as contas distintas
    TYPE tp_lista_contas IS TABLE OF VARCHAR2(100) INDEX BY PLS_INTEGER;

    lista_contas       tp_lista_contas;
    sql_dynamic        CLOB;
    colunas_pivot      CLOB := '';
    soma_colunas       CLOB := '';
    idx_conta          PLS_INTEGER := 0;

BEGIN
    --------------------------------------------------------------------------------
    -- 1. Remove a tabela temporária anterior, se existir
    --------------------------------------------------------------------------------
    BEGIN
        EXECUTE IMMEDIATE 'DROP TABLE tmp_consulta_incidencias_analiticas PURGE';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -942 THEN
                RAISE;
            END IF;
    END;

    --------------------------------------------------------------------------------
    -- 2. Preenche a lista de contas distintas no período e filtros informados
    --------------------------------------------------------------------------------
    FOR conta_reg IN (
        SELECT DISTINCT c.conta
        FROM funcionarios f
        JOIN calculos c ON f.empresa = c.empresa AND f.matricula = c.matricula
        JOIN periodos p ON c.referencia = p.referencia AND c.tipofolha = p.tipofolha
        JOIN incidencia i ON c.conta = i.conta
        WHERE p.referencia BETWEEN par_data_ini AND par_data_fim
          AND (par_tipofolha IS NULL OR c.tipofolha = par_tipofolha)
          AND (par_tipoincidencia IS NULL OR i.tipoincidencia = par_tipoincidencia)
        ORDER BY c.conta
    ) LOOP
        idx_conta := idx_conta + 1;
        lista_contas(idx_conta) := conta_reg.conta;
    END LOOP;

    --------------------------------------------------------------------------------
    -- 3. Gera as colunas dinâmicas para o PIVOT e a expressão da coluna total
    --------------------------------------------------------------------------------
    FOR i IN 1 .. lista_contas.COUNT LOOP
        -- Nome da coluna no SELECT
        colunas_pivot := colunas_pivot || '''' || lista_contas(i) || ''' AS "CONTA: ' || lista_contas(i) || '"';

        -- Expressão da soma para o campo total
        soma_colunas := soma_colunas || 'NVL("CONTA: ' || lista_contas(i) || '", 0)';

        -- Separadores
        IF i < lista_contas.COUNT THEN
            colunas_pivot := colunas_pivot || ', ';
            soma_colunas := soma_colunas || ' + ';
        END IF;
    END LOOP;

    --------------------------------------------------------------------------------
    -- 4. Monta a SQL dinâmica com SELECT + PIVOT + coluna total
    --------------------------------------------------------------------------------
    sql_dynamic := '
        CREATE TABLE tmp_consulta_incidencias_analiticas AS
        SELECT 
            periodo,
            cpf,
            matricula,
            nome, ';

    -- Adiciona colunas das contas (já com NVL)
    FOR i IN 1 .. lista_contas.COUNT LOOP
        sql_dynamic := sql_dynamic || 'NVL("CONTA: ' || lista_contas(i) || '", 0) AS "CONTA: ' || lista_contas(i) || '"';
        IF i < lista_contas.COUNT THEN
            sql_dynamic := sql_dynamic || ', ';
        END IF;
    END LOOP;

    -- Adiciona coluna "total"
    sql_dynamic := sql_dynamic || ', ' || soma_colunas || ' AS total';

    -- Continua o SELECT com PIVOT
    sql_dynamic := sql_dynamic || '
        FROM (
            SELECT 
                TO_CHAR(p.referencia, ''DD/MM/YYYY'') AS periodo,
                REGEXP_REPLACE(TO_CHAR(f.cpf), ''[^0-9]'', '''') AS cpf,
                f.matricula,
                f.nome,
                c.conta,
                c.valor
            FROM funcionarios f
            JOIN calculos c ON f.empresa = c.empresa AND f.matricula = c.matricula
            JOIN periodos p ON c.referencia = p.referencia AND c.tipofolha = p.tipofolha
            JOIN incidencia i ON c.conta = i.conta
            WHERE p.referencia BETWEEN TO_DATE(''' || TO_CHAR(par_data_ini, 'DD/MM/YYYY') || ''', ''DD/MM/YYYY'')
              AND TO_DATE(''' || TO_CHAR(par_data_fim, 'DD/MM/YYYY') || ''', ''DD/MM/YYYY'')
              AND (' || CASE WHEN par_tipofolha IS NULL THEN '1=1' ELSE 'c.tipofolha = ' || par_tipofolha END || ')
              AND (' || CASE WHEN par_tipoincidencia IS NULL THEN '1=1' ELSE 'i.tipoincidencia = ' || par_tipoincidencia END || ')
        )
        PIVOT (
            SUM(valor) FOR conta IN (' || colunas_pivot || ')
        )
        ORDER BY nome';

    --------------------------------------------------------------------------------
    -- 5. Executa a SQL gerada
    --------------------------------------------------------------------------------
    EXECUTE IMMEDIATE sql_dynamic;

    DBMS_OUTPUT.PUT_LINE('Tabela tmp_consulta_incidencias_analiticas criada com sucesso!');
END;