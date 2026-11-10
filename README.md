# Projecto de escola — loja online (2016)

Projeto escolar de 2016: uma loja online simples em PHP e MySQL, com catálogo por categorias, carrinho de compras, registo e login de clientes, histórico de encomendas e uma área de administração para gerir artigos e categorias.

> **EN-UK summary.** A 2016 school project: a small online shop in PHP and MySQL (catalogue, cart, customer accounts, order history and an admin area). Kept for reference only — it is not maintained and must not be deployed as is.

## Estado

Arquivo histórico, sem manutenção. O código usa a API `mysql_*`, removida no PHP 7, e guarda palavras-passe em texto simples. Serve como registo do projeto, não como base para uma loja real.

## Requisitos

- PHP 5.x com a extensão `mysql`
- MySQL ou MariaDB
- Um servidor web com PHP (por exemplo, Apache)

## Instalação

1. Copiar os ficheiros para a pasta servida pelo servidor web.
2. Criar a base de dados e importar `Epalte_ONLINE.sql`. Os clientes e o administrador do dump são fictícios.
3. Configurar as credenciais da base de dados (secção seguinte).

## Configuração

As credenciais da base de dados são lidas de variáveis de ambiente, nunca do código: `DB_USER` e `DB_PASSWORD`. O [`.env.example`](.env.example) é o modelo: copie para `.env`, preencha e defina as variáveis no ambiente do servidor web (por exemplo, com `SetEnv` no Apache). O `.env` é ignorado pelo git.

## Licença

Ver [LICENSE](LICENSE).

---

Created by Redfox using Claude
