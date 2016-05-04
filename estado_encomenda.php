<?php
//iniciar sessao
session_start();
//ligacao à base de dados
include("ligacao_db.php");
//verificar se o utilizador ja realizou o acesso
if(!isset($_SESSION['nivel_utilizador'==2])){
	echo"<tr>Nao esta autorizado a aceder a esta pagina!</tr>";
	echo"<tr><a href='index.php'>Clique aqui para voltar a pagina inicial</a></tr>";
}
else{
	if($_SESSION['nivel_utilizador']==2){
		$id_cliente=$_SESSION['id_cliente'];
		} 
		else{
		$id_cliente=!0;	
		}
		//pesquisar a base de dados
		$sql_quantidade = 'SELECT quantidade FROM compra_temporaria WHERE sessao="'.$sessao.'"AND id_artigo="'.$id_artigo.'"';
		//$sql_encomendas = "SELECT * FROM compra_confirmada WHERE estado_compra="'.zero'" AND id_cliente=".$id_cliente;
		$zero=0;
		//$sql_encomendas = 'SELECT * FROM compra_confirmada WHERE estado_compra="'.$zero'" AND id_cliente="'.$id_cliente.'"';
	//$sql_encomendas = 'SELECT * FROM compra_confirmada WHERE estado_compra IN ("'.$zero.'") AND id_cliente="'.$id_cliente.'"';
	echo".$id_cliente.";
		$sql_encomendas = "SELECT * FROM compra_confirmada WHERE estado_compra='0' AND id_cliente=".$id_cliente;
		
		
		$consulta = mysql_query($sql_encomendas);
		$resultado = mysql_num_rows($consulta);
		else {
			echo"<table width='800px' border='1' align='center'>";
			echo"<tr><td colspan='4' align='center'>Lista de encomendas</td></tr>";
			echo"<th>Nº Encom.</th><th>Nº cliente</th><th>Data da compra</th><th>Estado da compra</th>";
			while($mostrar = mysql_fetch_array($consulta)){
				extract($mostrar);
				echo'<tr>
				<td align="center">'.$id_compra.'</td>
				<td align="center" width="50px">'.$id_cliente.'</td>
				<td align="center">'.$data_compra.'</td>
				<td align="center">'.$estado_compra.'</td>
				</tr>';
				}
				echo"</table>";
			
				if($_SESSION['nivel_utilizador']==1){
					echo'<p align="center">Clique <a href="menu_admin.php">aqui</a> para voltar ao menu de administraçao</p>';}
					else{
					echo'<p align="center">Clique <a href="index.php">aqui>/a> para voltar a pagina inical</p>';}
					}
?>