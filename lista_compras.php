
<?php
//iniciar sessao
session_start();
//ligacao a base de dados
include('ligacao_db.php');
//Preparar sessao de compra
$sessao=session_id();
//pesquisar artigos no carrinho
$sql_carrinho ='SELECT * FROM compra_temporaria temp JOIN artigos prod ON temp.id_artigo = prod.id_artigo WHERE sessao="'.$sessao.'"ORDER BY temp.id_artigo ASC';
$consulta = mysql_query($sql_carrinho);
$resultado=mysql_num_rows($consulta);
if($resultado > 0){
	$total = 0;
	echo"<table width='800px' border='1' align='center'>";
	echo"<th>Imagem artigo </th><th>Detalhe Artigo</th><th>Quantidade</th><th>Preço unitario</th><th>Total a pagar</th>";
	while($mostrar = mysql_fetch_array($consulta)){
		extract($mostrar);
		echo"<tr><td align='center' width='100' height='100' valign='middle'><img src='$pasta_imagens".$imagem_artigo."'border='0'></a>";
		echo"<td align='center'><a href=\"comprar.php?id_artigo=$id_artigo&quantidade=$quantidade&submit=Alterar\">".$descricao_artigo."</td></a>";
		//formulario que permite alterar dados da compra
		echo"<form method='POST' action='atualizar_compra.php'>";
		echo"<td align='center'><input type='text' name='quantidade' size='2' value='$quantidade'</td>";
		echo"<input type='hidden' name='id_artigo' value='$id_artigo'/><input type='submit' name='submit' value='Alterar'/>";
		echo"</form>";
		//apresentar preco de cada artigo
		echo"<td align='center'>EUR".$preco_artigo."</td>";
		//calcular sub-total
		$sub_total=number_format($preco_artigo * quantidade,2);
		echo"<td align='center'>EUR".$sub_total."</td>";
		//calcular valor total de compras
		$total = $total + $preco_artigo * quantidade;}
		echo"<p align='center'>O valor total a pagar pelos artigos listados é de:<strong>EUR".number_format($total, 2)."</strong></p></td></tr>";
		echo'<form method="POST" action="finalizar_compra.php">';
		echo'<tr><td colspan="5" align="center"><p><input type="submit" name="submit" value="Finalizar compra"/></p></td></tr>';
		echo'</form>';
		echo"</table>";
}else{
	echo"<table width='800px' border='1' align='center'>";
	echo"<th>O seu carrinho de compras está vazio.Clique<a href=\"index.php\">aqui</a>para adicionar artigos</th>";}
?>