<?php
/*
  PT-PT: Verificacao de credenciais.

         Tres defeitos corrigidos aqui:
         1. A sessao era preenchida ANTES do teste de mysql_num_rows(), pelo que
            um login falhado ja tinha escrito estado de sessao antes de ser
            redireccionado.
         2. Liam-se as chaves 'id_utilizador' e 'nome_utilizador', que a consulta
            nunca seleciona -- os valores de sessao ficavam sempre NULL.
         3. $_POST entrava directamente no SQL. Sem escape, a autenticacao era
            contornavel com uma aspa.

         NOTA: a extensao mysql_* nao suporta consultas preparadas, por isso a
         mitigacao correcta aqui e mysql_real_escape_string(). A migracao para
         mysqli/PDO fica fora do ambito desta correccao.

  EN-UK: Credential check.

         Three defects fixed here:
         1. The session was populated BEFORE the mysql_num_rows() test, so a
            failed login had already written session state before redirecting.
         2. It read the keys 'id_utilizador' and 'nome_utilizador', which the
            query never selects -- the session values were always NULL.
         3. $_POST went straight into the SQL. With no escaping, authentication
            was bypassable with a single quote.

         NOTE: the mysql_* extension has no prepared statements, so the correct
         mitigation here is mysql_real_escape_string(). Migrating to mysqli/PDO
         is out of scope for this fix.
*/
session_start();
include("ligacao_db.php");

// PT-PT: Verificar que os campos do formulario foram preenchidos.
// EN-UK: Check the form fields were filled in.
if (empty($_POST['nome']) || empty($_POST['password'])) {
    header("Location:index.php");
    exit;
}

$username = mysql_real_escape_string($_POST['nome'], $ligacao);
$password = mysql_real_escape_string($_POST['password'], $ligacao);

$sql = "SELECT id_cliente, nome_login, palavra_passe, nivel_utilizador
        FROM clientes
        WHERE nome_login='$username' AND palavra_passe='$password'";
$consulta = mysql_query($sql, $ligacao);

// PT-PT: O guarda vem primeiro. Nada de sessao antes de haver exactamente uma
//        linha -- caso contrario um login falhado deixa estado escrito.
// EN-UK: The guard comes first. No session state before there is exactly one
//        row -- otherwise a failed login leaves state written behind it.
if (!$consulta || mysql_num_rows($consulta) != 1) {
    header("Location:index.php");
    exit;
}

$resultado = mysql_fetch_assoc($consulta);

// PT-PT: Renovar o identificador de sessao ao subir de privilegio, para que uma
//        sessao fixada antes do login deixe de servir.
// EN-UK: Regenerate the session id on privilege change, so a session fixed
//        before login is of no further use.
session_regenerate_id(true);

// PT-PT: As chaves tem de corresponder ao SELECT acima.
// EN-UK: The keys must match the SELECT above.
$_SESSION['id_cliente'] = $resultado['id_cliente'];
$_SESSION['nome_cliente'] = $resultado['nome_login'];
$_SESSION['nivel_utilizador'] = $resultado['nivel_utilizador'];

if ($_SESSION['nivel_utilizador'] == 1) {
    header("Location: menu_admin.php");
    exit;
} elseif ($_SESSION['nivel_utilizador'] == 2) {
    header("Location: Carrinho.php");
    exit;
}

header("Location:index.php");
exit;
?>
