<?php
/*
  PT-PT: Autenticacao a partir de index.php, contra a tabela `utilizadores`.
         (O outro caminho, login.php -> verifica_login.php, usa a tabela
         `clientes`. Sao dois sistemas de contas em paralelo, ambos activos.)

         Defeitos corrigidos:
         1. Contorno de autenticacao por injeccao de SQL. $_POST entrava
            directamente na consulta; bastava fechar a aspa para escolher a
            conta com que se entrava.
         2. Nao se iniciava sessao NENHUMA. Em caso de sucesso apenas se fazia
            header() para menu_admin.php -- a "autenticacao" era so um
            redireccionamento, e o painel era alcancavel escrevendo o URL.
         3. Qualquer conta autenticada era enviada para o painel de
            administracao, independentemente do nivel: um utilizador registado
            por registar_utilizador.php (nivel 2) recebia o menu de admin.
         4. Credenciais de root em codigo, e mysql_error() devolvido ao browser.

         NOTA: as palavras-passe estao guardadas em texto simples na base de
         dados. Corrigir isso obriga a migrar os registos existentes com
         password_hash()/password_verify() e nao pode ser feito so no codigo --
         fica assinalado no relatorio.

  EN-UK: Authentication from index.php against the `utilizadores` table.
         (The other path, login.php -> verifica_login.php, uses `clientes`.
         Two parallel account systems, both live.)

         Fixed: SQL-injection authentication bypass; the fact that NO session
         was ever started, so success was merely a redirect and the panel was
         reachable by typing the URL; every authenticated account being sent to
         the admin panel regardless of level; and in-code root credentials with
         mysql_error() echoed to the browser.

         NOTE: passwords are stored in plain text. Fixing that requires
         migrating existing rows with password_hash()/password_verify() and
         cannot be done in code alone -- flagged in the report.
*/
session_start();
include('ligacao_db.php');

if (empty($_POST['nome']) || empty($_POST['password'])) {
    header("Location: index.php");
    exit;
}

// PT-PT: mysql_* nao tem consultas preparadas; escapar e a mitigacao possivel.
// EN-UK: mysql_* has no prepared statements; escaping is the available fix.
$username = mysql_real_escape_string($_POST['nome'], $ligacao);
$password = mysql_real_escape_string($_POST['password'], $ligacao);

$sql = "SELECT id_utilizador, nome_utilizador, nivel_utilizador
        FROM utilizadores
        WHERE nome_utilizador='$username' AND palavra_passe='$password'";
$consulta = mysql_query($sql, $ligacao);

if (!$consulta || mysql_num_rows($consulta) != 1) {
    header("Location: index.php");
    exit;
}

$resultado = mysql_fetch_assoc($consulta);

// PT-PT: Renovar o identificador ao subir de privilegio, contra fixacao.
// EN-UK: Regenerate the id on privilege change, against session fixation.
session_regenerate_id(true);

// PT-PT: O resto da aplicacao le 'id_cliente' e 'nivel_utilizador' -- os
//        guardas incluidos, por isso e por estas chaves que a sessao e escrita,
//        mesmo vindo a linha da tabela `utilizadores`.
// EN-UK: The rest of the application reads 'id_cliente' and 'nivel_utilizador'
//        -- the guards included -- so the session is written under those keys
//        even though the row came from the `utilizadores` table.
$_SESSION['id_cliente'] = $resultado['id_utilizador'];
$_SESSION['nome_cliente'] = $resultado['nome_utilizador'];
$_SESSION['nivel_utilizador'] = $resultado['nivel_utilizador'];

// PT-PT: Encaminhar conforme o nivel. So o nivel 1 chega ao backoffice.
// EN-UK: Route by level. Only level 1 reaches the backoffice.
if ((int) $_SESSION['nivel_utilizador'] === 1) {
    header("Location: menu_admin.php");
    exit;
}

header("Location: Carrinho.php");
exit;
?>
