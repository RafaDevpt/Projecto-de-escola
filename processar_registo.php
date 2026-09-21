<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<head>
<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
<title>Menu Geral</title>
</head>
<?php
//verificar se o campo de utilizador e palavra-passe foram preenchidos
if (!empty(($_POST) AND (empty($_POST['nome']) OR empty($_POST['password']) OR empty($_POST['email']))) {
header("Location: registar_utilizador.php"); exit;
}
//ligar a base de dados
require ('acesso_bd.php');
$ligacao = myqsl_connect('localhost', 'root', '') or die ('Nao foi possivel ligar a base de dados');
//activar a base de dados pretendida
mysql_select_db($base_dados,  $ligacao) or die (mysql_error($ligacao));
//atribuir uma variavel aos dados recolhidos do formulario
/* PT-PT: Registo publico: todos os campos iam de $_POST para o INSERT sem
          qualquer tratamento, portanto injeccao sem autenticacao nenhuma.
          mysql_* nao tem consultas preparadas; escapa-se.
   EN-UK: Public registration: every field went from $_POST into the INSERT
          untreated, so injection with no authentication at all.
          mysql_* has no prepared statements; we escape. */
$username = mysql_real_escape_string($_POST['nome'], $ligacao);
$password = mysql_real_escape_string($_POST['password'], $ligacao);
$email = mysql_real_escape_string($_POST['email'], $ligacao);
$morada = mysql_real_escape_string($_POST['morada'], $ligacao);
$codigo_postal = mysql_real_escape_string($_POST['codigo_postal'], $ligacao);
$pais = mysql_real_escape_string($_POST['pais'], $ligacao);
$telefone = mysql_real_escape_string($_POST['telefone'], $ligacao);
$Localidade = $_POST['localidade'];
//cirar a instruçao para introduzir dados da tabela e executa-los
$sql="INSERT INTO Clientes (nome, password, email,  morada, codigo_postal, pais, telefone, localidade) VALUES ('$username', '$password', '$email', '$morada', '$codigo_postal', '$pais', '$telefone', '$localidade')";
$consulta = mysql_query($sql, $ligacao);
if ((consulta) !=1) {
//caso os dados nao sejam inseridos com sucesso, obriga a novo registo
header("Location: registar_utilizador.php"); exit;
}
else {
//caso os dados sejam inseridos com sucesso, insere o menu e apresenta mensagem de sucesso
include('index.php');
//mensagem de confirmaçao de registo inserido
echo"O registo foi efectuado com sucesso!<p>";
?>
<body>

</body>

</html>
