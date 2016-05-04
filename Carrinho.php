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
	<div id="menu-wrapper">
		<div id="menu" class="container">
			<ul>
				<li><a href="index.php">Homepage</a></li>
				<li><a href="Sobre.php">Sobre</a></li>
				<li><a href="Produtos.php">Produtos</a></li>
				<li><a href="Politica de Privacidade.php">Politica de Privacidade</a></li>
				<li><a href="Contacto.php">Contacto</a></li>
		     	<li class="current_page_item"><a href="Carrinho.php">Carrinho</a></li>
				<li><a href="login.php">Login</a></li>
			</ul>
		</div>
		<!-- end #menu --> 
	</div>
	<div id="banner"></div>
		<div id="page" class="container">
			<div class="title">
				<h2 align="center">Carrinho</h2>
				<p>
				<?php
				//iniciar sessao
				session_start();
				//ligacao a base de dados
				include('ligacao_db.php');
				//preparar sessao de compra
				$sessao = session_id();
				//pesquisar arigos no carrinho
				$sql_carrinho = 'SELECT * FROM compra_temporaria temp JOIN artigos prod ON temp.id_artigo = prod.id_artigo WHERE sessao="'.$sessao.'"ORDER BY temp.id_artigo ASC';
				$consulta = mysql_query($sql_carrinho);
				$resultado = mysql_num_rows($consulta);
				if($resultado > 0)
					{
					$total = 0;
					echo "<table width='800 px' border='1' align='center'>";
					echo "<th>Imagem artigo</th><th> Detalhe Artigo</th><th>Quantidade</th><th>Preço unitario</th><th>Total a pagar</th>";
						while($mostrar = mysql_fetch_array($consulta)) 
						{
						extract($mostrar);
						echo "<tr><td align='center' width='100' height='100' valign='middle'><img src='$pasta_imagens".$imagem_artigo."' border='0'></a>";
						echo "<td align='center'><a href=\"comprar.php\">".$descricao_artigo."</td></a>";
						//formulario que permite alterar dados da compra
						echo "<form method='POST' action='atualizar_compra.php'>";
						echo "<td align='center'><input type='text' name='quantidade' size='2' value='$quantidade'</td>";
						echo "<input type='hidden' name='id_artigo' value='$id_artigo'/><input type='submit' name='submit' value='Alterar'/>";
						echo "</form>";
						//apresentar preço de cada artigo
						echo "<td align='center' EUR".$preco_artigo."</td>";
						//calcular sub-total
						$sub-total == number_format($preco_artigo * $quantidade, 2);
						echo "<td align='center'>EUR".$sub_total."</td>";
						//calcular valor total de compras
						$total = $total + $preco_artigo * $quantidade;
						}
					echo "<p align='center'>O valor total a pagar pelos artigos Listados é de:<strong>EUR".number_format($total,2)."</strong></p></td></tr>";
					echo '<form method="POST" action="finalizar_compra.php">';
					echo '<tr><td colspan="5" align="center"><p><input type="submit" name="submit" value="Finalizar compra"/></p></td></tr>';
					echo "</form>";
					echo "</table>";
					}
				else 
					{
					echo "<table width='800' border='1' align='center'>";
					echo "<th>O seu carrinho de compras esta vazio. Clique <a href=\"Produtos.php\">aqui</a> para adicionar artigos!</th>";
					}
				?>
				</div>
				</p>
<div id="copyright" class="container">
	<p>© epalte online. All rights reserved. | Designed by dispenserstock team</p>
</div>
</body>
</html>
