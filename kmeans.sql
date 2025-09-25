--1 criar tabelas

--a)Tabela de Centroides - com k linhas
DROP TABLE Centroides
CREATE TABLE Centroides(
	cluster_id INT PRIMARY KEY,
	embedding VECTOR(384)
);

--b)Tabela dos Clusters - cada ponto com o id do cluster designado
DROP TABLE Clusters
CREATE TABLE Clusters(
	id BIGINT PRIMARY KEY,
	centroide_id INT,
	dist FLOAT
);

--c)Tabela dos Clusters antigos - compara se houve mudança - usado como critério de parada
DROP TABLE Clusters_old
CREATE TABLE Clusters_old(
	id BIGINT PRIMARY KEY,
	centroide_id INT,
	dist FLOAT
);

--PRIMEIRA RODADA  (todo esse bloco foi movido para a função KMeans)

-- -- escolher k centroides de maneira aleatória na base de dados
-- INSERT INTO Centroides (cluster_id, embedding)
-- SELECT
--     ROW_NUMBER() OVER () AS cluster_id,
--     embeddings
-- FROM (
--     SELECT embeddings
--     FROM teste 
--     ORDER BY RANDOM() 
--     LIMIT 4          --VALOR DE K
-- ) AS LinhasAleatorias;

-- --calcular distâncias e criar clusters

-- INSERT INTO Clusters SELECT DISTINCT ON (t.id) 
--     t.id AS teste_id,
--     c.cluster_id,
--     t.embeddings <-> c.embedding AS distancia
-- FROM
--     teste AS t
-- CROSS JOIN
--     Centroides AS c
-- ORDER BY
--     t.id,
--     distancia ASC;
	
	
-- --atualizar os centroides com a média dos seus pontos
-- UPDATE Centroides c
-- SET
--     embedding = nc.novo_embedding
-- FROM (
--     SELECT
--         cl.centroide_id,
--         AVG(t.embeddings) AS novo_embedding
--     FROM
--         teste AS t
--     JOIN
--         -- Junta os dados com suas atribuições de cluster da etapa anterior
--         Clusters AS cl ON t.id = cl.id
--     GROUP BY
--         cl.centroide_id -- Agrupa por cluster para que o AVG() funcione para cada um separadamente
-- ) AS nc -- "nc" é um alias para "novos_centroides"
-- WHERE
--     c.cluster_id = nc.centroide_id;
	
-- --salvar clusters_old
-- INSERT INTO Clusters_old SELECT * FROM Clusters

-- --PROXIMAS RODADAS
-- --recalcular distâncias

-- UPDATE Clusters 
-- SET id=ncl.teste_id, centroide_id=ncl.cluster_id, dist=ncl.distancia
-- FROM (
-- SELECT DISTINCT ON (t.id) 
--     t.id AS teste_id,
--     c.cluster_id,
--     t.embeddings <-> c.embedding AS distancia
-- FROM
--     teste AS t
-- CROSS JOIN
--     Centroides AS c
-- ORDER BY
--     t.id,
--     distancia ASC
-- ) AS ncl
-- WHERE
--     id = ncl.teste_id;

-- --verificar critério de parada (se for a primeira interação ignorar)
-- (SELECT id,centroide_id FROM Clusters EXCEPT SELECT id,centroide_id FROM Clusters_old)
-- UNION ALL
-- (SELECT id,centroide_id FROM Clusters_old EXCEPT SELECT id,centroide_id FROM Clusters);

-- --caso retorne null->FIM caso não atualiza centroides
-- UPDATE Centroides c
-- SET
--     embedding = nc.novo_embedding
-- FROM (
--     SELECT
--         cl.centroide_id,
--         AVG(t.embeddings) AS novo_embedding
--     FROM
--         teste AS t
--     JOIN
--         -- Junta os dados com suas atribuições de cluster da etapa anterior
--         Clusters AS cl ON t.id = cl.id
--     GROUP BY
--         cl.centroide_id -- Agrupa por cluster para que o AVG() funcione para cada um separadamente
-- ) AS nc -- "nc" é um alias para "novos_centroides"
-- WHERE
--     c.cluster_id = nc.centroide_id;
	
-- --atualizar clusters_old
-- UPDATE Cluster_old SET id=id, centroide_id=centroide_id, dist=dist FROM Clusters

-- --REPETE calculo das distâncias
-- DROP FUNCTION kmeans(integer,integer)

CREATE OR REPLACE FUNCTION KMeans(k INT, max_iteracoes INT)
RETURNS TABLE(ponto_id BIGINT, cluster_atribuido_id INT, distancia FLOAT) AS $$
DECLARE
    iteracao INT := 0;
    houve_mudanca BOOLEAN := TRUE;
BEGIN
    TRUNCATE TABLE Centroides;

    INSERT INTO Centroides (cluster_id, embedding)
    SELECT
        ROW_NUMBER() OVER () AS cluster_id,
        embeddings
    FROM (
        SELECT embeddings
        FROM teste
        ORDER BY RANDOM()
        LIMIT k
    ) AS LinhasAleatorias;

    RAISE NOTICE 'K-Means: Inicialização com % centroides concluída.', k;

    WHILE iteracao < max_iteracoes AND houve_mudanca LOOP
        iteracao := iteracao + 1;
        RAISE NOTICE 'Iniciando iteração %...', iteracao;

        -- a) Salva o estado anterior dos clusters para comparação
        TRUNCATE TABLE Clusters_old;
        INSERT INTO Clusters_old SELECT * FROM Clusters;

        -- b) Passo de Atribuição: Calcula as novas distâncias e atribui os clusters
        TRUNCATE TABLE Clusters;
        INSERT INTO Clusters (id, centroide_id, dist)
        SELECT DISTINCT ON (t.id)
            t.id,
            c.cluster_id,
            t.embeddings <-> c.embedding
        FROM
            teste AS t
        CROSS JOIN
            Centroides AS c
        ORDER BY
            t.id,
            t.embeddings <-> c.embedding ASC;

        RAISE NOTICE 'Iteração %: Passo de Atribuição concluído.', iteracao;

        -- c) Critério de Parada: Verifica se houve alguma mudança nas atribuições
        -- Se a contagem de diferenças for 0, o loop irá parar na próxima verificação.
        SELECT EXISTS (
            SELECT 1
            FROM (
                (SELECT id, centroide_id FROM Clusters EXCEPT SELECT id, centroide_id FROM Clusters_old)
                UNION ALL
                (SELECT id, centroide_id FROM Clusters_old EXCEPT SELECT id, centroide_id FROM Clusters)
            ) AS diferencas
        ) INTO houve_mudanca;

        IF NOT houve_mudanca THEN
            RAISE NOTICE 'Iteração %: Algoritmo convergiu. Não houve mudanças.', iteracao;
            EXIT; -- Sai do loop imediatamente
        END IF;

        -- d) Passo de Atualização: Recalcula a posição dos centroides
        UPDATE Centroides centroide_set
        SET
            embedding = novos.novo_embedding
        FROM (
            SELECT
                cl.centroide_id,
                AVG(t.embeddings) AS novo_embedding
            FROM
                teste AS t
            JOIN
                Clusters AS cl ON t.id = cl.id
            GROUP BY
                cl.centroide_id
        ) AS novos
        WHERE
            centroide_set.cluster_id = novos.centroide_id;

        RAISE NOTICE 'Iteração %: Passo de Atualização dos centroides concluído.', iteracao;

    END LOOP;

    IF iteracao >= max_iteracoes THEN
        RAISE NOTICE 'K-Means: Atingido o número máximo de iterações (%).', max_iteracoes;
    END IF;
	RETURN QUERY SELECT * FROM Clusters;

    RAISE NOTICE 'K-Means: Processo finalizado.';

END;
$$ LANGUAGE plpgsql;


DROP TABLE teste;
CREATE TABLE teste(
	id BIGINT PRIMARY KEY,
	tweet_text TEXT,
	tweet_date TIMESTAMPTZ,
	sentimento TEXT,
	tokens TEXT,
	embeddings VECTOR(384)
);

TRUNCATE teste;

INSERT INTO teste
SELECT * FROM dados_twitter;


-- TABLE resultado
CREATE TABLE resultado(
	ponto_id BIGINT,
	cluster_atribuido_id INT,
	distancia FLOAT
);

-- RESULTADOS
--k=5
INSERT INTO resultado select * FROM KMeans(5,300);
--Cluster 1
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=1;
--Cluster 2
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=2;
--Cluster 3
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=3;
--Cluster 4
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=4;
--Cluster 5
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=5;


--Selecionando os 10 vizinhos mais próximos do centroide de cada cluster

--Cluster 1
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=1 ORDER BY distancia LIMIT 10;
--Cluster 2
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=2 ORDER BY distancia LIMIT 10;
--Cluster 3
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=3 ORDER BY distancia LIMIT 10;
--Cluster 4
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=4 ORDER BY distancia LIMIT 10;
--Cluster 5
SELECT * FROM teste T JOIN resultado ON T.id=ponto_id WHERE cluster_atribuido_id=5 ORDER BY distancia LIMIT 10;




