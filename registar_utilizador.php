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
//ligacao a base de dados
include("ligacao_db.php");
//verificar se foi clicado o botao de registar topico(submit)
if(isset($_REQUEST['registar'])) {
	//verificar se os campos do formulario estao preenchidos
	if (!empty($_POST) AND (empty($_POST['nickname']) OR empty($_POST['password']))) {
		echo "<table class='tabela_baixo' align='center' width='800px'><tr><td>J!</td>";
		echo "<td><a href='registar_utilizador.php'>Clique para tentar de novo!</a></td>";
	}
	//verificar se ja existe um utilizador registado coim o mesmo nome
	$nickname = $_POST['nickname'];
	$sql="SELECT * FROM utilizadores WHERE nome_utilizador='$nickname'";
	$consulta=mysql_query($sql);
	$resultado=mysql_num_rows($consulta);
	//se ja existe utilizador, apresenta mensagem de erro
	if($resultado !=0){
		echo"<table class='tabela_baixo' align='center' width='800px'><tr><td>Já existe um utilizador com este nome de acesso!</td>";
		echo"<td><a href='registar_utilizador.php'>Clique para tentar de novo!</a></td>";
	}
	else{
		//se nao existe utilizador com o mesmo nome, cria novo registo
	$sql2="INSERT INTO utilizadores(nome_utilizador, palavra_passe, email, nivel_utilizador) VALUES('".$_POST['nickname']."','".$_POST['password']."','".$_POST['email']."','2')";
	$consulta2=mysql_query($sql2);
	echo"<table class='tabela_baixo' align='center' width='800px'><tr><td>Obrigado por se registar!</td>";
	echo"<td><a href='index.php'>Clique para continuar!</a></td>";
	}
}
?>
<table class="tabela_baixo" width="800px" align="center" border=0>
<tr class="Titulos"><td colspan="2" align="center">Insira os dados para se registar</td></tr>
<form id="form_registo" name="form_registo" action="registar_utilizador.php" method="POST">
<tr>
<td>Nome de acesso: <input type="text" name="nickname" size=10>*</td>
</tr>
<tr>
<td>Palavra-passe: <input type="password" name="password" size=8>*</td>
</tr>
<tr>
<td>Endereço de correio electronico:<input type="text" name="email" size=30>*</td>
</tr>
<tr>
<td>* Campo obrigatório
</tr>
<td>
<input type="submit" name="registar" value="Enviar">
<input type="reset" name="apagar" value="Apagar"></td>
</tr>
</table>
</form>
<form method="POST" action="finalizar_compra2.php">
<tr><td colspan="2"><input type="submit" value="Concluir a compra"></td></tr>
</form>
<?php }
?>
	</p>
			</div>
		</div>
<div id="copyright" class="container">
	<p>© epalte online. All rights reserved. | Designed by dispenserstock team</p>
</div>
</body>
</html>