# TCC: Análise de Sentimentos em Tweets usando pgvector e K-means

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-F37626?style=flat&logo=jupyter&logoColor=white)

Este repositório contém o código-fonte do Trabalho de Conclusão de Curso (TCC) que implementa um sistema de análise de sentimentos em tweets utilizando embeddings vetoriais com pgvector e clustering K-means no PostgreSQL.

**Autora:** Ana Luísa Matias Corsi

## Visão Geral

O projeto realiza análise de sentimentos em tweets em português utilizando:
- **Embeddings vetoriais** para representação semântica dos tweets
- **pgvector** como extensão do PostgreSQL para operações vetoriais
- **Algoritmo K-means** para clustering e análise de similaridade
- **Busca por similaridade** usando diferentes métricas de distância (L1, L2, Cosseno)



## Descrição dos Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `pre_processamento.ipynb` | Notebook Jupyter para processamento e geração de embeddings dos tweets |
| `add_db.py` | Script Python para conexão e inserção dos dados processados no PostgreSQL |
| `script.sql` | Comandos SQL para criação da estrutura de dados e consultas de similaridade |
| `kmeans.sql` | Implementação do algoritmo K-means diretamente no PostgreSQL |

## Como Executar

### Pré-requisitos

- PostgreSQL com extensão pgvector instalada
- Python 3.x com as seguintes bibliotecas:
  - `pandas`
  - `numpy`
  - `psycopg2`
  - `pgvector`
- Conta no Kaggle para acesso ao dataset

### Passo a Passo

1. **Pré-processamento dos Dados**
   ```
   - Acesse o ambiente Kaggle: https://www.kaggle.com/code
   - Carregue o notebook pre_processamento.ipynb
   - Selecione o dataset: https://www.kaggle.com/datasets/augustop/portuguese-tweets-for-sentiment-analysis
   - Execute o notebook completo
   - Baixe o arquivo newdb.csv gerado
   ```

2. **Configuração do Banco de Dados**
   ```sql
   -- Execute no seu PostgreSQL local
   CREATE EXTENSION IF NOT EXISTS vector;
   ```
   Execute a primeira parte do `script.sql` para criar a tabela `dados_twitter`

3. **Configuração da Conexão**
   - Edite o arquivo `add_db.py`
   - Configure as credenciais do seu PostgreSQL:
     ```python
     dbname="postgres",
     user="seu_usuario",
     password="sua_senha", 
     host="seu_host",
     port="sua_porta"
     ```

4. **Inserção dos Dados**
   ```bash
   python add_db.py
   ```

5. **Consultas de Similaridade**
   ```sql
   -- Execute o restante do script.sql para realizar:
   -- - Consultas KNN com diferentes métricas
   -- - Análises de similaridade vetorial
   ```

6. **Clustering K-means**
   ```sql
   -- Execute kmeans.sql para:
   -- - Aplicar clustering nos embeddings
   -- - Visualizar resultados do agrupamento
   ```



## Tecnologias Utilizadas

- **PostgreSQL** - Sistema de gerenciamento de banco de dados
- **pgvector** - Extensão para operações vetoriais no PostgreSQL
- **Python** - Linguagem para processamento de dados
- **Jupyter Notebook** - Ambiente de desenvolvimento interativo
- **Pandas/Numpy** - Bibliotecas para manipulação de dados
- **psycopg2** - Conector Python-PostgreSQL

## Dataset

Este projeto utiliza o dataset ["Portuguese Tweets for Sentiment Analysis"](https://www.kaggle.com/datasets/augustop/portuguese-tweets-for-sentiment-analysis) disponível no Kaggle, que contém tweets em português classificados por sentimento.

## Contexto Acadêmico

Este trabalho foi desenvolvido como Trabalho de Conclusão de Curso, explorando as capacidades do PostgreSQL com pgvector para análise de sentimentos em grande escala, demonstrando como SGBDs relacionais podem ser utilizados eficientemente para processamento de dados vetoriais e machine learning.

## Licença
Este projeto é desenvolvido para fins acadêmicos. 

Todas as referências e fontes estão disponíveis no trabalho de TCC. 
