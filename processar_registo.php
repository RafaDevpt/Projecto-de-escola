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
$username = $_POST['nome'];
$password = $_POST['password'];
$email = $_POST['email'];
$morada = $_POST['morada'];
$codigo_postal = $_POST['codigo_postal'];
$pais = $_POST['pais'];
$telefone = $_POST['telefone'];
$Localidade = $_POST['localidade'];
//cirar a instruçao para introduzir dados da tabela e executa-los
$sql="INSERT INTO Clientes (nome, password, email,  morada, codigo_postal, pais, telefone, localidade) VALUES '$username', '$password', '$email', '$morada', '$codigo_postal', '$pais', '$telefone', '$localidade')";
$consulta = mysql_query($sql);
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
