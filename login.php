<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>EPALTE Online - Login</title>
<link href="../default.css" rel="stylesheet" type="text/css" media="all" />
<link href="../fonts.css" rel="stylesheet" type="text/css" media="all" />
<link href="default_ie6.css" rel="stylesheet" type="text/css" />
</head>
<body style="background-image:url('../images/madeira.jpg')">
	<div id="wrapper">
	<div id="header-wrapper">
		<div id="header" class="container">
			<div id="logo">
				<h1><a href="#">EPALTE Online</a></h1>
				<p>Design by: DispenserStock Team</p>
			</div>
			</div>
			</div>
			<div id="menu-wrapper">
		<div id="menu" class="container">
			<ul>
				<li><a href="index.php">Homepage</a></li>
				<li><a href="Sobre.php">Sobre</a></li>
				<li><a href="Produtos.php">Produtos</a></li>
				<li><a href="Politica de Privacidade.php">Politica de Privacidade</a></li>
				<li><a href="Contacto.php">Contacto</a></li>
				<li><a href="Carrinho.php">Carrinho</a></li>
				<li class="current_page_item"><a href="login.php">Login</a></li>
			</ul>
		</div>
	</div>
	<div id="banner"></div>
	<div id="page" class="container">
	<div class="title">
				<h2 align="center">Login</h2>
				</div>
<table width="800" border="0" align="center" cellspacing="0">
<tr>
<form id="form_registo" name="form_registo" method="POST" action="verifica_login.php">
<td align="left" valign="top">Nome de utilizador:
<input type="text" name="nome" id="nome"/>Palavra-passe:
<input type="password" name="password" id="password"/>
<a href="registo_cliente.php">Novo Utilizador?</a></td></tr>
<tr><td><input type="submit" name="entrar" id="entrar" value="Entrar"/>
<tr><td><input type="reset" name="apagar" id="apagar" value="Apagar"/></td></tr>
</tr>
</form>
</table>
</body>
</html>