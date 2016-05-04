<?php
//ligacao à base de dados
session_start();
include("ligacao_db.php");
//verficar os campos do formulario foram preeenchidos
if (!empty($_POST) AND (empty($_POST['nome']) OR (empty($_POST['password'])))) {
	

header("Location:index.php");
exit;
}
$username=$_POST['nome'];
$password=$_POST['password'];
//consultar a base de dados
$sql="SELECT id_cliente, nome_login, palavra_passe, nivel_utilizador FROM clientes WHERE nome_login='$username' AND palavra_passe='$password'";
$consulta = mysql_query($sql);
$resultado=mysql_fetch_assoc($consulta);
//atribui dados encontrados na sessao
$_SESSION['id_cliente']=$resultado['id_utilizador'];
$_SESSION['nome_cliente']=$resultado['nome_utilizador'];
$_SESSION['nivel_utilizador']=$resultado['nivel_utilizador'];
if (mysql_num_rows($consulta)!=1) {
//possbilidade 1: redirecciona o utilizador se nao esta registado
header("Location:index.php");
exit;
} elseif ($_SESSION['nivel_utilizador']==1){
	$_SESSION['id_cliente'] = $resultado['id_cliente'];
	header("Location: menu_admin.php"); exit;
} elseif ($_SESSION['nivel_utilizador']==2){
	$_SESSION['id_cliente'] = $resultado['id_cliente'];
	header("Location: Carrinho.php"); exit;
}
?>