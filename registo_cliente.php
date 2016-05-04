<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>EPALTE Online - Registo</title>
<link href="../default.css" rel="stylesheet" type="text/css" media="all" />
<link href="../fonts.css" rel="stylesheet" type="text/css" media="all" />
<!--[if IE 6]>
<link href="../default_ie6.css" rel="stylesheet" type="text/css" />
<![endif]-->
<style type="text/css">
.auto-style1 {
	width: 1200px;
	margin-right: auto;
	margin-top: 0px;
	margin-bottom: 0px;
}
</style>
</head>
<body style="background-image:url('../images/madeira.jpg')">
<div id="wrapper">
	<div id="header-wrapper">
		<div id="header" class="container" style="left: 0px; top: 0px">
			<div id="logo">
				<h1><a href="#">EPALTE Online</a></h1>
				<p>Design by: DispenserStock Team</p>
			</div>
		</div>
	</div>
			<table width="800" border="0" align="center" cellspacing="0">
			<tr>
			<form id="form_registo" name="form_registo" method="post" action="processa_login.php">
			<td align="left" valign="top">Nome de Utilizador:
			<input type="text" name="nome" id="nome"/>Palavra-Passe:
			<input type="password" name="password" id="password"/>
			<a href="registo_cliente.php">Novo Utilizador?</a></td>
			<tr><td><input type="reset" name="apagar" id="apagar" value="Apagar"/></td></tr>
			<tr><td><input type="submit" name="confirmar" id="confirmar" value="confirmar"/></td></tr>
			</form>
			</tr>
			</table>
	<div id="menu-wrapper">
		<div id="menu" class="container">
			<ul>
				<li><a href="index.php">Homepage</a></li>
				<li><a href="Sobre.php">Sobre</a></li>
				<li><a href="Produtos.php">Produtos</a></li>
				<li><a href="Politica de Privacidade.php">Politica de Privacidade</a></li>
				<li><a href="Contacto.php">Contacto</a></li>
		     	<li class="current_page_item"><a href="Carrinho.php">Carrinho</a></li>
			</ul>
		</div>
		<!-- end #menu --> 
	</div>
	<div id="banner"></div>
	<div id="page" class="auto-style1">
		<div id="content">
			<div class="title">
				<h2>Registo</h2>
				<p>
<?php
//Iniciar sessao
session_start();
//Registar Utilizador
if(isset($_REQUEST['registar'])){
//ligaçao a base de dados
include('ligacao_db.php');
$sql_cliente = "INSERT INTO clientes(nome_login, palavra_passe, primeiro_nome, apelido, endereco, localidade, codigo_postal, telefone, email, nivel_utilizador) VALUES ( 
'".$_POST['nome_login']."',
'".$_POST['palavra_passe']."',
'".$_POST['primeiro_nome']."',
'".$_POST['apelido']."',
'".$_POST['endereco']."',
'".$_POST['localidade']."',
'".$_POST['codigo_postal']."',
'".$_POST['telefone']."',
'".$_POST['email']."','2')";
$consulta = mysql_query($sql_cliente);
//remeter para pagina de de entrada
header("Location: index.php");
}
?>
<form id="form_registo" name="form_registo" method="POST" action="registo_cliente.php">
<table width="800" border="1" cellspacing="0" cellpadding="0" align="center">
<th colspan="2">Registo de Cliente</th>
<tr><td width="200">Nome de acesso:</td>
<td width="600"><input type="text" name="nome_login" size="20"/></td>
</tr>
<tr><td>Palavra-passe:</td>
<td><input type="password" name="palavra_passe" size="8"/>(MAX: 8 caracteres)</td>
</tr>
<tr><td>Primeiro Nome:</td>
<td><input type="text" name="primeiro_nome" size="15"/>
</td>
</tr>
<tr><td>Apelido:</td>
<td><input type="text" name="apelido" size="25"/>
</td>
</tr>
<tr><td>Endereço (Rua/Lugar):</td>
<td><input type="text" name="endereco" size="50"/>
</td>
</tr>
<tr><td>Localidade:</td>
<td><input type="text" name="localidade" size="25"/>
</td>
</tr>
<tr><td>Codigo Postal:</td>
<td><input type="text" name="codigo_postal" size="8"/>
</td>
</tr>
<tr><td>Telefone:</td>
<td><input type="text" name="telefone" size="25"/>
</td>
</tr>
<tr><td>Endereço de correio electronico</td>
<td><input type="text" name="email" size="50"/>
</td>
</tr>
<td colspan="2" align="center"><input type="submit" name="registar" id="registar" value="Registar"/>
<input type="reset" name="apagar" id="apagar" value="Apagar"/>
<p>Clique<a href="index.php"> aqui </a>para voltar à HomePage</p>
</td>
</table>
</form>
	</p>
			</div>
		</div>
<div id="copyright" class="container">
	<p>© epalte online. All rights reserved. | Designed by dispenserstock team</p>
</div>
</body>
</html>