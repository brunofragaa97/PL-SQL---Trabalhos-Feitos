rel ficha funcional

WITH
    dados_funcionario AS (
    SELECT
        --PESSOAL
        cpf(fv.cpf) AS cpf,
        fv.nome AS nome,
        fv.matricula AS matricula,
        CASE 
            WHEN fv.sexo = 'F' THEN 'FEMININO'
            WHEN fv.sexo = 'M' THEN 'MASCULINO'
       END as sexo,
       fv.dtnascimento AS dt_nascimento,
       fv.dtidentidade as dt_identidade,
       fv.nmnatural as cidade_natural,
       --FILIAÇÃO
       fv.pai AS nome_pai,
       fv.mae AS nome_mae,
       --ESTADO CIVIL
       CASE
            WHEN fv.ec = 1 THEN 'Casado(a)'
            WHEN fv.ec = 2 THEN 'Solteiro(a)'
            WHEN fv.ec = 1 THEN 'Disquitado(a)'
            WHEN fv.ec = 4 THEN 'Divorciado(a)'
        END AS estado_civil,
        --ENDEREÇO
        nmlogradouro AS nome_rua,
        nmbairro AS nome_bairro,
        nmcidade AS nome_cidade,
        cep AS cep,
        --ESCOLARIDADE
        nmgrauinst AS grau_instrucao,
        --INFORMAÇÕES COMPLEMENTARES
        titulo AS numero_titulo_eleitor,
        zona AS numero_zona,
        sessao AS numero_sessao,
        titulouf AS uf_do_titulo,
        --CARTEIRA PROFISSIONAL
        cpnumero AS cp_numero,
        cpserie AS cp_serie,
        pis(pis) AS passep,
        --IDENTIDADE FUNCIONAL
        CASE
            WHEN credencial IS NULL  THEN 'Não informado'
        END AS credencial,
         CASE
            WHEN reservista IS NULL  THEN 'Não informado'
        END AS carteira_reservista,
        --DADOS FUNCIONAIS
        nmcargo AS cargo_efetivo,
        nivel
        FROM funcionarios_view fv
        WHERE fv.matricula = 6295
        )
            select distinct * from  dados_funcionario;
            
            
            select * from funcionarios;
            select * from dependentes;
            select * from funcionarios_view;