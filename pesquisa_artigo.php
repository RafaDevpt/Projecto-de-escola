	<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>EPALTE Online - Carrinho</title>
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
				<h2>Produto</h2>
				<p>
	<?php
	//pesquisar artigos
	if(isset($_REQUEST['pesquisar'])){
		//ligacao a base de dados
		include('ligacao_db.php');
		//pesquisar termo inserido
		$termo_pesquisa = '%'.$_POST['termo_pesquisa'].'%';
		$sql_artigo = "SELECT * FROM artigos WHERE nome_artigo LIKE'$termo_pesquisa'";
		$consulta = mysql_query($sql_artigo);
		$resultado = mysql_num_rows($consulta);
		if($resultado !=0){
			echo"<table width='800px' border='1' align='center'>";
			echo"<th>Artigos encontrados na pesquisa com o termo ".$_POST['termo_pesquisa']."</th>";
			//apresentar artigos disponiveis
			while($mostrar = mysql_fetch_array($consulta)){
				echo"<table width='800px' border='1' align='center'>";
				echo"<tr>";
				echo"<td align='center' width='100' height='100' valign='middle'><img src='$pasta_imagens".$mostrar['imagem_artigo']."'border='0'></td>";
				echo"<td><align='center'>".$mostrar['nome_artigo']."</a></br>EUR".$mostrar['preco_artigo']."</br>".$mostrar['descricao_artigo']."</td>";
				echo"<td width='200' align='left' valign='middle'></br><a href='comprar.php?id_artigo=".$mostrar['id_artigo']."'><img border=0 src='images/carrinho.jpg'></td></tr>";
				echo"</table>";
			}
		}
		//caso nao haja artigos, informa utilizador
		else{
			echo"<table width='800px' border='1' align='center'>";
	echo"<td align='center'>Nao foram encontrados artigos que correspondem ao criterio!";
		}
	}
	?>
	</p>
			</div>
		</div>
<div id="copyright" class="container">
	<p>© epalte online. All rights reserved. | Designed by dispenserstock team</p>
</div>
</body>
</html>