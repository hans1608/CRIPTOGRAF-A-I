-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Servidor: 127.0.0.1
-- Tiempo de generación: 29-04-2025 a las 04:03:29
-- Versión del servidor: 10.4.32-MariaDB-log
-- Versión de PHP: 8.1.25

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de datos: `colegio`
--

DELIMITER $$
--
-- Procedimientos
--
CREATE DEFINER=`dzxual4qerhr`@`localhost` PROCEDURE `sp_anularecibo` (IN `_tiporeci` INT, IN `_serie` VARCHAR(20), IN `_reci` VARCHAR(20), IN `_usua` INT, IN `_ip` VARCHAR(20), IN `_host` VARCHAR(20), OUT `_result` VARCHAR(500))   BEGIN
DECLARE _codiReci INT;
DECLARE _codiSubCuot INT;
DECLARE _codiCuot INT;
DECLARE _monto INT;
DECLARE _desc INT;
DECLARE _codiserv INT;

select -- s.codiTipoReci,
	r.codiReci /*, r.numeReci ,  s.descSeri as serie*/
	, sc.codiSubCuot , sc.montAbon , sc.montDesc , sc.codiCuot , c.codiServ
into _codiReci, _codiSubCuot, _monto, _desc, _codiCuot, _codiserv
from recibo  r
inner join serie s on r.codiSeri = s.codiSeri 
inner join subcuota sc on r.codiReci =sc.codiReci 
inner join cuota c on sc.codiCuot = c.codiCuot
inner join (
	select c.codiServ, s.codiTipoReci , max(r.codiReci ) as ultimo_recibo  
	from recibo r 
	inner join serie s on r.codiSeri =s.codiSeri
	inner join subcuota sc on sc.codiReci = r.codiReci 
	inner join cuota c  on sc.codiCuot = c.codiCuot   
	where r.estdReci ='P' and r.actiReci =1 and r.fechRegiAlta between date(now()) and now()
		and s.actiSeri =1 and sc.actiSubCuot =1 and c.actiCuot =1
	group by c.codiServ,s.codiTipoReci
) ur on r.codiReci = ur.ultimo_recibo
where s.codiTipoReci =_tiporeci and s.descSeri=_serie  and  r.numeReci=_reci;

IF _codiReci is not null THEN
	update subcuota 
    set estdSubCuot ='A'
    , codiUsuaModi = _usua
    , fechRegiModi = now()
    , ipRegiModi = _ip
    , hostRegiModi = _host
    where codiSubCuot=_codiSubCuot;
    
    update cuota
    set montAbon = montAbon - _monto
    ,  montDeud = montDeud + _monto + _desc
    , estdCuot = 'D'
    , codiUsuaModi = _usua
    , fechRegiModi = now()
    , ipRegiModi = _ip
    , hostRegiModi = _host
    where codiCuot=_codiCuot;
    
    update recibo 
    set estdReci='A'
    , codiUsuaModi = _usua
    , fechRegiModi = now()
    , ipRegiModi = _ip
    , hostRegiModi = _host
    where codiReci=_codiReci;
	
 	SET _result='{"resultado":"ok"}';
ELSE
	SET _result='{"resultado":"error","mensaje":"recibo invalido, o no cumple condiciones para anular."}';
END IF;

END$$

CREATE DEFINER=`dzxual4qerhr`@`localhost` PROCEDURE `sp_anula_matricula` (IN `_codiSev` INT, IN `_user` INT, IN `_ip` VARCHAR(20), IN `_host` VARCHAR(20), OUT `_result` VARCHAR(500))   BEGIN


SET _result='{"result","ok"}';
END$$

CREATE DEFINER=`dzxual4qerhr`@`localhost` PROCEDURE `sp_listar` (IN `pcodiServ` INT)   select `se`.`codiServ` AS `codiServ`,`au`.`codiAula` AS `codiAula`,`se`.`codiAlum` AS `codiAlum`,`cu`.`codiCuot` AS `codiCuot`,`an`.`nombAnio` AS `nombAnio`,`cu`.`codiConc` AS `codiConc`,`co`.`nombConc` AS `nombConc`,`cu`.`montDeud` AS `montDeud`,`cu`.`montDesc` AS `montDesc`,`cu`.`montAbon` AS `montAbon`,`cu`.`estdCuot` AS `estdCuot`,case when `cu`.`montDeud` = (select min(`colegio`.`cuota`.`montDeud`) 
from `colegio`.`cuota` where `cu`.`codiServ` = `colegio`.`cuota`.`codiServ` and `cu`.`codiServ`=pcodiServ) then 1 else 0 end AS `cuotaMinima` 
from ((((`colegio`.`servicio` `se` join `colegio`.`aula` `au` on (`se`.`codiAula` = `au`.`codiAula` and `se`.`codiServ` = pcodiServ)) 
        join `colegio`.`anio` `an` on(`au`.`codiAnio` = `an`.`codiAnio`)) 
       join `colegio`.`cuota` `cu` on (`cu`.`codiServ` = `se`.`codiServ` and `cu`.`estdCuot` = 'D' and `cu`.`codiServ`=pcodiServ)) 
      join `colegio`.`concepto` `co` on(`cu`.`codiConc` = `co`.`codiConc`))$$

CREATE DEFINER=`dzxual4qerhr`@`localhost` PROCEDURE `sp_matricular` (IN `_codiAlum` MEDIUMINT, IN `_codiAula` INT, IN `_codiUsua` INT, IN `ip` VARCHAR(20), IN `host` VARCHAR(20), OUT `result` VARCHAR(255))  NO SQL BEGIN
    DECLARE resultado VARCHAR(50);
    DECLARE mensaje VARCHAR(255);
    DECLARE nro_pensiones integer;
    DECLARE matriculado bit;
    DECLARE _codiServ INTEGER;
    DECLARE ahora DATETIME; 
    
	
    
    SET ahora=(SELECT CURDATE());
    SET resultado = 'error';
    SET mensaje = '';
    SET matriculado=0;
    SET _codiServ=NULL;
    
	-- Captura de errores
    -- DECLARE CONTINUE  HANDLER FOR SQLEXCEPTION
    -- BEGIN
    --     ROLLBACK;
    --     SET result = '{"resultado":"Error","mensaje":"Error en la transacción","matricula":""}';
    -- END;

   
    SET _codiServ=NULL;
    set nro_pensiones =NULL;
    /*revisa si existe otra matricula activa estdServ='G' en año actual*/
    SET _codiServ=(select MAX(`codiServ`)as nr
                  from servicio 
                  where `codiAlum`=_codiAlum 
                  	and `estdServ`='G' 
                  	and `actiServ`=1 
                  	and `codiAula` in (
        				SELECT `codiAula` 
                        FROM aula 
                        WHERE `actiAula`=1 and `codiAnio` IN (
                        	SELECT  `codiAnio` FROM aula WHERE `codiAula`=_codiAula
                        )
                    )  
                 );
    
    if (_codiServ is not null) then  
    	
       SET mensaje=concat('No deben existir matricula activa en el mismo año, matricula:',cast(_codiServ as char));
    ELSE
    
    		SET nro_pensiones= (select count(1) as rs 
								from tipoconcepto t
								inner join concepto con on t.codiTipoConc =con.codiTipoConc 
								inner join tarifa tar on t.codiTipoConc =tar.codiTipoConc
								inner join aula a on tar.codiSede = a.codiSede 
									and a.codiGrad =tar.codiGrad
								where actiTipoConc =1 and matrTipoConc =1 
									and tar.actiTari =1
									and a.actiAula =1
									and a.codiAula =_codiAula);
			IF nro_pensiones is null  THEN
				SET mensaje='Parametros inválidos';
            ELSEIF nro_pensiones=0 THEN
				SET mensaje='No se puede matricular si no existe conceptos';
			ELSE			
				/*ageregando matricula*/
				INSERT INTO `servicio`(`codiAlum`, `codiAula`, `estdServ`,  `codiUsuaAlta`, `fechRegiAlta`,`ipRegiAlta`,`hostRegiAlta`,  `codiUsuaModi`, `fechRegiModi`,`ipRegiModi`,`hostRegiModi`,`actiServ`)
                VALUES (_codiAlum, _codiAula, 'G', _codiusua,now(), ip, host, _codiusua, now(), ip, host, 1);
				/*nueva matricula*/
				SET _codiServ=(SELECT LAST_INSERT_ID());
				/*agregando cuota*/
            
				INSERT INTO `cuota`( `codiServ`, `codiConc`, `montDeud`, `montAbon`, `montDesc`, `estdCuot`
					, `fechVenc`
					, `nombCuot`
					, `CodiUsuaAlta`, `fechRegiAlta`,`ipRegiAlta`,`hostRegiAlta`
					, `codiUsuaModi`, `fechRegiModi`,`ipRegiModi`,`hostRegiModi`
					, `actiCuot`)
				    
				select  _codiServ, con.`codiConc`, tar.`montTari` as montDeud, 0 as montAbon, 0 as montDesc,'D' as estdCuot 
					, coalesce(DATE_SUB(DATE_ADD(STR_TO_DATE(CONCAT(an.`nombAnio`, '-', con.`codiMes`  , '-', '01'), '%Y-%m-%d') , INTERVAL 1 MONTH), INTERVAL 1 DAY) ,now()) as fechVenc
				    , concat(con.`nombConc`,'-',an.nombAnio , ' - ',g.nombGrad,' ', n.nombNive) as nombCuot
				    , _codiUsua as CodiUsuaAlta, now() as fechRegiAlta, ip as ipRegiAlta, host as hostRegiAlta
				    , _codiUsua as CodiUsuaModi, now() as fechRegiModi, ip as ipRegiModi, host as hostRegiModi
				    , 1 as actiCuot
				from tipoconcepto t
				inner join concepto con on t.codiTipoConc =con.codiTipoConc 
				inner join tarifa tar on t.codiTipoConc =tar.codiTipoConc
				inner join aula a on tar.codiSede = a.codiSede 	and a.codiGrad =tar.codiGrad
				inner join grado g  on a.codiGrad =g.codiGrad 
				inner join nivel n on g.codiNive  =  n.codiNive 
				inner join anio an on a.codiAnio =an.codiAnio
				where actiTipoConc =1 and matrTipoConc =1 
					and tar.actiTari =1
					and a.actiAula =1
					and a.codiAula =_codiAula
					and g.actiGrado=1
					and n.actiNive=1;
                
				SET resultado='ok';
				SET mensaje=concat('Se matriculó correctamente, se generaron (',cast(nro_pensiones as VARCHAR(2)),') registros');
			
		
		end if;
    end if;
    -- Finaliza la transacción
    IF (_codiServ IS NOT NULL ) THEN
    set result=  CONCAT('{"resultado":"', resultado, '","mensaje":"', mensaje, '","matricula":"', cast(_codiServ as VARCHAR(10)) , '"}') ;
    ELSE
    set result=  CONCAT('{"resultado":"', resultado, '","mensaje":"', mensaje, '","matricula":""}') ;
    END IF;
END$$

CREATE DEFINER=`dzxual4qerhr`@`localhost` PROCEDURE `sp_pagar` (IN `_codiServ` INT, IN `_caja` INT, IN `_fpago` TINYINT, IN `_pago` FLOAT, IN `_numeOper` VARCHAR(20), IN `_user` VARCHAR(20), IN `_ip` VARCHAR(20), IN `_host` VARCHAR(20), OUT `_result` VARCHAR(255))   BEGIN
	DECLARE _deudaTotal FLOAT;
	DECLARE _seri INT;
	DECLARE _reci INT;
	DECLARE _cuota INT;
	DECLARE _ahora DATETIME;
	DECLARE _p FLOAT;
	DECLARE _sc INTEGER;
	DECLARE _d FLOAT;
	DECLARE _m FLOAT;
	DECLARE _r int;
	DECLARE _df FLOAT;
    DECLARE _er INT;
    DECLARE _msg varchar(250);
	set _er=1;
    
    
 	CREATE TEMPORARY TABLE IF NOT EXISTS pago_temp (
 		codiServ INT,
        codiCuot INT,
        montDeud FLOAT,
        montAbon FLOAT,
        nuevadeuda FLOAT,
        nuevoabonado FLOAT,
        monto_reci FLOAT,
        codiSeri INT,        
        numeReci INT,
        continua INT,
         codiSubCuot INT,
        codiReci INT 
	);
    
	SET _ahora=NOW();
    SET _deudaTotal = (SELECT  SUM(montDeud)  as deuda 
                       FROM cuota c 
                       WHERE c.actiCuot = 1 AND c.codiServ = _codiServ AND estdCuot IN ('D'));
    
    set _er = 1;
    IF(_deudaTotal <= 0) THEN 
		set _msg = 'ERROR, No tiene deuda';		
        
    ELSEIF(_pago<=0) THEN 
		set _msg='ERROR, Pago no puede ser menor o igual a cero';		
	ELSEIF (_pago>=_deudaTotal) THEN 
		set _msg='ERROR, Pago no puede ser mayor a la deuda total';
    ELSE
    	set _er = 0;
	END IF;
    
	IF (_er < 1) THEN
		
		INSERT INTO pago_temp (codiServ, codiCuot, montDeud, montAbon
			, nuevadeuda, nuevoabonado, codiSeri, numeReci, continua, monto_reci)
        SELECT p.codiServ, p.codiCuot, p.montDeud, p.montAbon
            , p.nuevadeuda, p.montAbon + (p.montDeud - p.nuevadeuda) AS nuevoabonado            
            , r.codiSeri
            , ultiom_reci+ (ROW_NUMBER() OVER (ORDER BY p.codiCuot asc) ) AS numeReci 
            , -(ROW_NUMBER() OVER (ORDER BY p.codiCuot desc) -1) AS continua
            , p.montDeud - p.nuevadeuda as monto_reci
        FROM (
			SELECT codiServ, codiCuot, montDeud, montAbon, montDesc
            	, monto_acum, pago , monto_acum_dif
            	, CASE WHEN monto_acum_dif < 0 THEN 0 ELSE monto_acum_dif END AS nuevadeuda
                , COALESCE(LAG(monto_acum) OVER (PARTITION BY codiServ ORDER BY codiCuot), 0) AS ultimo        
            FROM (
				SELECT c.codiServ, c.codiCuot, montDeud, montAbon, montDesc
                	, SUM(montDeud) OVER (PARTITION BY c.codiServ ORDER BY c.codiCuot) AS monto_acum
                	, SUM(montDeud) OVER (PARTITION BY c.codiServ ORDER BY c.codiCuot) - _pago AS monto_acum_dif
                	, _pago as pago
            	FROM cuota c
            	WHERE c.actiCuot = 1 AND c.codiServ = _codiServ AND estdCuot IN ('D')
         	)dat 
            where monto_acum_dif <montDeud
        ) p
        , (
			select c.codiSeri ,coalesce(max(numeReci),c.ultmNumeReci) as ultiom_reci
            from cajaserie c 
            inner join serie s on c.codiSeri = c.codiSeri 
            left join recibo r on s.codiSeri = r.codiSeri and r.actiReci =1
            where c.codiCaja =_caja and actiCajaSeri =1 and s.actiSeri =1 
            group by c.codiSeri 
		) r 
        WHERE p.ultimo < p.pago
        order by p.codiCuot;

		insert into recibo (codiSeri, montReci, codiFormPago, numeOper, estdReci, actiReci
        	, codiUsuaAlta, fechRegiAlta, ipRegiAlta, hostRegiAlta
            , codiUsuaModi, fechRegiModi, ipRegiModi, hostRegiModi
            , numeReci
		)
        select codiSeri, monto_reci , _fpago, _numeOper,'P',1
        	, _user , _ahora , _ip ,  _host
            , _user , _ahora , _ip ,  _host
            , numeReci
		from pago_temp
        order by codiCuot;
        
        set _r= LAST_INSERT_ID();
            
        update pago_temp set codiReci = _r+continua; 
        
        

        INSERT INTO subcuota (codiCuot, montAbon, montDesc, estdSubCuot, actiSubCuot, codiReci
        	, codiUsuaAlta, fechRegiAlta, ipRegiAlta, hostRegiAlta
            , codiUsuaModi, fechRegiModi, ipRegiModi, hostRegiModi
       	)
        select codiCuot, monto_reci, 0, 'P', 1, codiReci
        	,_user , _ahora , _ip ,  _host
            ,_user , _ahora , _ip ,  _host
        from pago_temp;

		set _sc= LAST_INSERT_ID(); 

        update pago_temp  set codiSubCuot= _sc+continua ;
		
        update recibo r
        join  pago_temp pt on r.codiReci = pt.codiReci
        set r.codiSubCuot = pt.codiSubCuot;
        
		update cuota c
        join pago_temp pt on c.codiCuot = pt.codiCuot
        set c.montDeud = c.montDeud - pt.monto_reci
			, c.montAbon = c.montAbon+ pt.monto_reci
            , c.codiUsuaModi = _user
            , c.fechRegiModi = _ahora
            , c.ipRegiModi = _ip
            , c.hostRegiModi = _host;
        
        update cuota c
        join pago_temp pt on c.codiCuot = pt.codiCuot
        SET estdCuot = case when c.montDeud=0 then 'P' else 'D' end;
        
        update servicio set estdServ='A' where codiServ=_codiServ and estdServ='G';
        
        SET _result = CONCAT('{"resultado":"ok", "recibos":[{',(
             select GROUP_CONCAT( CONCAT('"recibo":"',codiReci,'"') ORDER BY numeReci ASC SEPARATOR ', ') AS recibos from pago_temp),'}]}');
    else 
    	SET _result =concat('{"resultado":"error","mensaje":"',_msg,'"}');
    END IF;


END$$

CREATE DEFINER=`dzxual4qerhr`@`localhost` PROCEDURE `sp_test` (IN `codiServ` INT)  NO SQL SELECT '{"resultado":"ok"}' AS resultado$$

--
-- Funciones
--
CREATE DEFINER=`dzxual4qerhr`@`localhost` FUNCTION `handle_errors` () RETURNS VARCHAR(255) CHARSET latin1 COLLATE latin1_swedish_ci  BEGIN
    RETURN 'error';
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `acceso`
--

CREATE TABLE `acceso` (
  `codiUsua` int(11) DEFAULT NULL,
  `codiSede` smallint(6) DEFAULT NULL,
  `codiAccs` int(11) NOT NULL,
  `actiAccs` bit(1) DEFAULT NULL,
  `codiUsuaAlta` int(11) DEFAULT NULL,
  `fechRegiAlta` date DEFAULT NULL,
  `codiUsuaModi` int(11) DEFAULT NULL,
  `fechRegiModi` date DEFAULT NULL,
  `ipRegiModi` varchar(20) DEFAULT NULL,
  `ipRegiAlta` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `acceso`
--

INSERT INTO `acceso` (`codiUsua`, `codiSede`, `codiAccs`, `actiAccs`, `codiUsuaAlta`, `fechRegiAlta`, `codiUsuaModi`, `fechRegiModi`, `ipRegiModi`, `ipRegiAlta`) VALUES
(1, 1, 1, b'1', 1, '2023-11-06', NULL, NULL, NULL, 'localhost'),
(1, 1, 2, b'0', 1, '2023-11-06', NULL, NULL, NULL, 'localhost');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `alumno`
--

CREATE TABLE `alumno` (
  `codiAlum` mediumint(9) NOT NULL,
  `codiTipoDocu` char(2) DEFAULT NULL,
  `codiUbig` char(6) DEFAULT NULL,
  `codiVia` smallint(6) DEFAULT NULL,
  `numeDocu` varchar(15) DEFAULT NULL,
  `appaAlum` varchar(70) DEFAULT NULL,
  `apmaAlum` varchar(70) DEFAULT NULL,
  `nombAlum` varchar(70) DEFAULT NULL,
  `raznSociAlum` varchar(210) DEFAULT NULL,
  `mailAlum` varchar(50) DEFAULT NULL,
  `sexoAlum` char(1) DEFAULT NULL,
  `celuAlum` varchar(15) DEFAULT NULL,
  `celuAlum2` varchar(15) DEFAULT NULL,
  `celualum3` varchar(15) DEFAULT NULL,
  `direServ` varchar(100) DEFAULT NULL,
  `numeDireServ` varchar(5) DEFAULT NULL,
  `numInteServ` varchar(10) DEFAULT NULL,
  `refeDireServ` varchar(100) DEFAULT NULL,
  `codiEstdMinedu` varchar(15) DEFAULT NULL,
  `clavAlum` varchar(80) DEFAULT NULL,
  `codiUsuaAlta` int(11) DEFAULT NULL,
  `fechRegiAlta` datetime DEFAULT NULL,
  `codiUsuaModi` int(11) DEFAULT NULL,
  `fechRegiModi` datetime DEFAULT NULL,
  `actiAlum` bit(1) DEFAULT NULL,
  `ipRegiAlta` varchar(20) DEFAULT NULL,
  `ipRegiModi` varchar(20) DEFAULT NULL,
  `hostRegiAlta` varchar(20) DEFAULT NULL,
  `hostRegiModi` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `alumno`
--

INSERT INTO `alumno` (`codiAlum`, `codiTipoDocu`, `codiUbig`, `codiVia`, `numeDocu`, `appaAlum`, `apmaAlum`, `nombAlum`, `raznSociAlum`, `mailAlum`, `sexoAlum`, `celuAlum`, `celuAlum2`, `celualum3`, `direServ`, `numeDireServ`, `numInteServ`, `refeDireServ`, `codiEstdMinedu`, `clavAlum`, `codiUsuaAlta`, `fechRegiAlta`, `codiUsuaModi`, `fechRegiModi`, `actiAlum`, `ipRegiAlta`, `ipRegiModi`, `hostRegiAlta`, `hostRegiModi`) VALUES
(1, '01', '140501', 1, '40801418', 'CHINGA', 'RAMOS', 'CARLOS ENRIQUE', NULL, '', 'V', '', NULL, NULL, '', '', '', '', '', NULL, 1, '2023-12-26 19:28:58', 1, '2023-12-26 19:28:58', b'1', NULL, NULL, NULL, NULL),
(2, '01', '140501', 1, '15638953', 'RAMOS', 'VELASQUEZ', 'FLOR ESTELA', NULL, '', 'V', '', NULL, NULL, '', '', '', '', '', NULL, 1, '2023-12-26 22:11:37', 1, '2023-12-26 22:11:37', b'1', NULL, NULL, NULL, NULL),
(3, '01', '140501', 1, '76554304', 'CHINGA', 'MELENDEZ', 'ABI', NULL, '', 'V', '', NULL, NULL, '', '', '', '', '', NULL, 1, '2023-12-26 23:10:03', 1, '2024-01-06 13:02:50', b'1', NULL, 'iperror', NULL, 'hosterror'),
(4, '01', '140501', 1, '71982587', 'JARA', 'ALVARADO', 'NOE', NULL, 'NOEJARA@GMAIL.COM', 'V', '985674852', NULL, NULL, 'AV. FLORES', '11', '', '', '', NULL, 1, '2024-01-06 13:05:41', 1, '2024-01-06 13:05:41', b'1', NULL, NULL, NULL, NULL),
(5, '01', '140502', 1, '74985632', 'SANCHEZ', 'CASTRO', 'MARIELA', NULL, 'MARIELA@GMAIL.COM', 'M', '985674852', NULL, NULL, 'AV. FLORES', '14', '', '', '', NULL, 1, '2024-01-06 16:03:08', 1, '2024-01-06 16:03:08', b'1', NULL, NULL, NULL, NULL),
(6, '01', '140501', 1, '71854698', 'TORRES', 'VALDES', 'SARA', NULL, 'NIVE@GMAIL.COM', 'M', '985674852', NULL, NULL, 'AV. UGARTE', '45', '', '', '', NULL, 1, '2024-01-06 16:44:21', 1, '2024-01-06 16:44:21', b'1', NULL, NULL, NULL, NULL),
(7, '01', '140501', 1, '71985874', 'TORRES', 'ALVA', 'JOSE', NULL, 'JOSE@GMAIL.COM', 'V', '985632574', NULL, NULL, 'AV. FLORES', '14', '', '', '', NULL, 1, '2024-01-07 10:49:52', 1, '2024-01-07 10:49:52', b'1', NULL, NULL, NULL, NULL),
(8, '01', '140501', 1, '71985632', 'SUAREZ', 'GARRO', 'MARTIN', NULL, 'MARTIN@GMAIL.COM', 'V', '985632574', NULL, NULL, 'AV. ALFONSO', '74', '', '', '', NULL, 1, '2024-01-07 11:48:15', 1, '2024-01-07 11:48:15', b'1', NULL, NULL, NULL, NULL),
(11, '01', '140501', 1, '78546325', 'SANCHES', 'SIA', 'DAN', NULL, 'DANIELA@GMAIL.COM', 'V', '97854632', NULL, NULL, 'AV. FLORES', '30', '', '', '', NULL, 1, '2024-01-07 11:55:16', 1, '2024-01-07 11:55:16', b'1', NULL, NULL, NULL, NULL),
(12, '01', '140501', 1, '8965741', 'ZUAREA', 'TORRES', 'MARIA', NULL, 'MARIA64GMAIL.COM', 'M', '985632741', NULL, NULL, 'AV. FLORES', '16', '', '', '', NULL, 1, '2024-01-07 12:05:29', 1, '2024-01-07 12:05:29', b'1', NULL, NULL, NULL, NULL),
(13, '01', '140501', 1, '98632475', 'BER', 'ZAS', 'JULIA', NULL, 'JULIA@GMAIL.COM', 'M', '985632874', NULL, NULL, 'AV. ALFONSO', '56', '', '', '', NULL, 1, '2024-01-07 12:27:49', 1, '2024-01-07 12:27:49', b'1', NULL, NULL, NULL, NULL),
(14, '01', '140501', 1, '45895632', 'SILVA', 'FUENTE', 'CAMILA', NULL, 'CAMILA@GMAIL.COM', 'M', '985632587', NULL, NULL, 'AV. FLORES', '14', '', '', '', NULL, 1, '2024-01-10 23:24:41', 1, '2024-01-10 23:24:41', b'1', NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `anio`
--

CREATE TABLE `anio` (
  `codiAnio` smallint(6) NOT NULL,
  `nombAnio` varchar(4) DEFAULT NULL,
  `actiAnio` bit(1) DEFAULT NULL,
  `acadAnio` bit(1) DEFAULT NULL,
  `matrAnio` bit(1) DEFAULT NULL,
  `repoAnio` bit(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `anio`
--

INSERT INTO `anio` (`codiAnio`, `nombAnio`, `actiAnio`, `acadAnio`, `matrAnio`, `repoAnio`) VALUES
(1, '2024', b'1', b'1', b'1', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `aula`
--

CREATE TABLE `aula` (
  `codiGrad` tinyint(4) DEFAULT NULL,
  `codiSecc` tinyint(4) DEFAULT NULL,
  `codiAnio` smallint(6) DEFAULT NULL,
  `codiAula` int(11) NOT NULL,
  `numeAula` tinyint(4) DEFAULT NULL,
  `codiUsuaAlta` int(11) DEFAULT NULL,
  `fechRegiAlta` datetime DEFAULT NULL,
  `codiUsuaModi` int(11) DEFAULT NULL,
  `fechRegiModi` datetime DEFAULT NULL,
  `codiSede` smallint(6) NOT NULL,
  `actiAula` bit(1) DEFAULT NULL,
  `ipRegiAlta` varchar(20) DEFAULT NULL,
  `ipRegiModi` varchar(20) DEFAULT NULL,
  `hostRegiAlta` varchar(20) DEFAULT NULL,
  `hostRegiModi` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `aula`
--

INSERT INTO `aula` (`codiGrad`, `codiSecc`, `codiAnio`, `codiAula`, `numeAula`, `codiUsuaAlta`, `fechRegiAlta`, `codiUsuaModi`, `fechRegiModi`, `codiSede`, `actiAula`, `ipRegiAlta`, `ipRegiModi`, `hostRegiAlta`, `hostRegiModi`) VALUES
(1, 1, 1, 1, 30, 1, '2023-10-29 16:32:11', 1, '2024-01-06 13:03:51', 1, b'1', 'localhost', 'iperror', 'pc', 'hosterror'),
(2, 1, 1, 2, 30, 1, '2023-11-01 12:39:55', 1, '2023-11-12 09:09:35', 1, b'1', NULL, '127.0.0.1', NULL, 'DESKTOP-KOHJ357'),
(3, 1, 1, 3, 30, 1, '2023-11-01 12:51:11', 1, '2023-11-15 09:36:46', 1, b'1', '181.66.150.229', '127.0.0.1', NULL, 'DESKTOP-KOHJ357'),
(4, 1, 1, 4, 30, 1, '2023-11-26 07:55:21', 1, '2023-11-26 07:55:21', 1, b'1', '127.0.0.1', '127.0.0.1', 'DESKTOP-KOHJ357', 'DESKTOP-KOHJ357'),
(5, 1, 1, 5, 30, 1, '2023-11-26 07:55:32', 1, '2023-11-26 07:55:32', 1, b'1', '127.0.0.1', '127.0.0.1', 'DESKTOP-KOHJ357', 'DESKTOP-KOHJ357'),
(6, 1, 1, 6, 30, 1, '2023-11-26 07:55:38', 1, '2023-11-26 07:55:38', 1, b'1', '127.0.0.1', '127.0.0.1', 'DESKTOP-KOHJ357', 'DESKTOP-KOHJ357'),
(7, 1, 1, 7, 30, 1, '2023-11-26 07:55:43', 1, '2023-11-26 07:55:43', 1, b'1', '127.0.0.1', '127.0.0.1', 'DESKTOP-KOHJ357', 'DESKTOP-KOHJ357'),
(8, 1, 1, 8, 30, 1, '2023-11-26 07:55:49', 1, '2023-11-26 07:55:49', 1, b'1', '127.0.0.1', '127.0.0.1', 'DESKTOP-KOHJ357', 'DESKTOP-KOHJ357'),
(9, 1, 1, 9, 30, 1, '2023-11-26 07:55:55', 1, '2023-11-26 07:55:55', 1, b'1', '127.0.0.1', '127.0.0.1', 'DESKTOP-KOHJ357', 'DESKTOP-KOHJ357');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `caja`
--

CREATE TABLE `caja` (
  `codiSede` smallint(6) DEFAULT NULL,
  `codiCaja` smallint(6) NOT NULL,
  `actiCaja` bit(1) DEFAULT NULL,
  `hostCaja` varchar(20) DEFAULT NULL,
  `descCaja` varchar(80) DEFAULT NULL,
  `codiUsuaAlta` int(11) DEFAULT NULL,
  `fechRegiAlta` date DEFAULT NULL,
  `ipRegiAlta` varchar(20) DEFAULT NULL,
  `codiUsuaModi` int(11) DEFAULT NULL,
  `fechRegiModi` date DEFAULT NULL,
  `ipRegiModi` varchar(20) DEFAULT NULL,
  `hostRegiAlta` varchar(20) DEFAULT NULL,
  `hostRegiModi` varchar(20) DEFAULT NULL,
  `ipCaja` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `caja`
--

INSERT INTO `caja` (`codiSede`, `codiCaja`, `actiCaja`, `hostCaja`, `descCaja`, `codiUsuaAlta`, `fechRegiAlta`, `ipRegiAlta`, `codiUsuaModi`, `fechRegiModi`, `ipRegiModi`, `hostRegiAlta`, `hostRegiModi`, `ipCaja`) VALUES
(1, 1, b'1', 'LAPTOP', 'CAJA PRINCIPAL', 1, '2023-11-19', 'LOCALHOST', 1, '2023-11-19', 'LOCALHOST', 'LAPTOP', 'LAPTOP', 'locahost');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cajaserie`
--

CREATE TABLE `cajaserie` (
  `codiCaja` smallint(6) DEFAULT NULL,
  `codiSeri` tinyint(4) DEFAULT NULL,
  `codiCajaSerie` int(11) NOT NULL,
  `ultmNumeReci` int(11) DEFAULT NULL,
  `actiCajaSeri` bit(1) DEFAULT NULL,
  `codiUsuaAlta` int(11) DEFAULT NULL,
  `hostCaja` varchar(20) DEFAULT NULL,
  `ipRegiAlta` varchar(20) DEFAULT NULL,
  `fechRegiAlta` date DEFAULT NULL,
  `codiUsuaModi` int(11) DEFAULT NULL,
  `fechRegiModi` date DEFAULT NULL,
  `ipRegiModi` varchar(20) DEFAULT NULL,
  `hostRegiModi` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `cajaserie`
--

INSERT INTO `cajaserie` (`codiCaja`, `codiSeri`, `codiCajaSerie`, `ultmNumeReci`, `actiCajaSeri`, `codiUsuaAlta`, `hostCaja`, `ipRegiAlta`, `fechRegiAlta`, `codiUsuaModi`, `fechRegiModi`, `ipRegiModi`, `hostRegiModi`) VALUES
(1, 1, 1, 0, b'1', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `concepto`
--

CREATE TABLE `concepto` (
  `codiConc` smallint(6) NOT NULL,
  `codiMes` tinyint(4) DEFAULT NULL,
  `nombConc` varchar(45) DEFAULT NULL,
  `actiConc` bit(1) DEFAULT NULL,
  `ordeConc` tinyint(4) DEFAULT NULL,
  `codiTipoConc` tinyint(4) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `concepto`
--

INSERT INTO `concepto` (`codiConc`, `codiMes`, `nombConc`, `actiConc`, `ordeConc`, `codiTipoConc`) VALUES
(1, 3, 'PENSION MARZO', b'0', 2, 2),
(2, 4, 'PENSION ABRIL', b'1', 3, 2),
(3, 5, 'PENSION MAYO', b'1', 4, 2),
(4, 6, 'PENSION JUNIO', b'0', 5, 2),
(5, 7, 'PENSION JULIO', b'0', 6, 2),
(6, 8, 'PENSION AGOSTO', b'1', 7, 2),
(7, 9, 'PENSION SETIEMBRE', b'1', 8, 2),
(8, 10, 'PENSION OCTUBRE', b'1', 9, 2),
(9, 11, 'PENSION NOVIEMBRE', b'1', 10, 2),
(10, 12, 'PENSION DICIEMBRE', b'1', 11, 2),
(11, NULL, 'MATRICULA', b'1', 1, 1);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `cuota`
--

CREATE TABLE `cuota` (
  `codiServ` int(11) DEFAULT NULL,
  `codiCuot` int(11) NOT NULL,
  `codiConc` smallint(6) DEFAULT NULL,
  `montDeud` float DEFAULT NULL,
  `montAbon` float DEFAULT NULL,
  `montDesc` float DEFAULT NULL,
  `estdCuot` char(1) DEFAULT NULL,
  `fechVenc` date DEFAULT NULL,
  `obsvCuot` text DEFAULT NULL,
  `codiUsuaAlta` int(11) DEFAULT NULL,
  `fechRegiAlta` datetime DEFAULT NULL,
  `codiUsuaModi` int(11) DEFAULT NULL,
  `fechRegiModi` datetime DEFAULT NULL,
  `actiCuot` bit(1) DEFAULT NULL,
  `ipRegiAlta` varchar(20) DEFAULT NULL,
  `ipRegiModi` varchar(20) DEFAULT NULL,
  `nombCuot` varchar(250) DEFAULT NULL,
  `hostRegiAlta` varchar(20) DEFAULT NULL,
  `hostRegiModi` varchar(20) DEFAULT NULL,
  `moraCuot` float DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `cuota`
--

INSERT INTO `cuota` (`codiServ`, `codiCuot`, `codiConc`, `montDeud`, `montAbon`, `montDesc`, `estdCuot`, `fechVenc`, `obsvCuot`, `codiUsuaAlta`, `fechRegiAlta`, `codiUsuaModi`, `fechRegiModi`, `actiCuot`, `ipRegiAlta`, `ipRegiModi`, `nombCuot`, `hostRegiAlta`, `hostRegiModi`, `moraCuot`) VALUES
(1, 1, 11, 150, 0, 0, 'D', '2023-12-26', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'MATRICULA-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 2, 1, 200, 0, 0, 'D', '2024-03-31', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION MARZO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 3, 2, 200, 0, 0, 'D', '2024-04-30', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION ABRIL-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 4, 3, 200, 0, 0, 'D', '2024-05-31', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION MAYO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 5, 4, 200, 0, 0, 'D', '2024-06-30', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION JUNIO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 6, 5, 200, 0, 0, 'D', '2024-07-31', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION JULIO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 7, 6, 200, 0, 0, 'D', '2024-08-31', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION AGOSTO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 8, 7, 200, 0, 0, 'D', '2024-09-30', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION SETIEMBRE-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 9, 8, 200, 0, 0, 'D', '2024-10-31', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION OCTUBRE-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 10, 9, 200, 0, 0, 'D', '2024-11-30', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION NOVIEMBRE-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(1, 11, 10, 200, 0, 0, 'D', '2024-12-31', NULL, 1, '2023-12-26 17:29:05', 1, '2023-12-26 17:29:05', b'1', '190.239.221.201', '190.239.221.201', 'PENSION DICIEMBRE-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(2, 16, 11, 150, 0, 0, 'D', '2023-12-26', NULL, 1, '2023-12-26 20:11:43', 1, '2023-12-26 20:11:43', b'1', '190.239.221.201', '190.239.221.201', 'MATRICULA-2024 - 4 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 17, 11, 150, 0, 0, 'D', '2023-12-26', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'MATRICULA-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 18, 1, 200, 0, 0, 'D', '2024-03-31', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION MARZO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 19, 2, 200, 0, 0, 'D', '2024-04-30', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION ABRIL-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 20, 3, 200, 0, 0, 'D', '2024-05-31', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION MAYO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 21, 4, 200, 0, 0, 'D', '2024-06-30', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION JUNIO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 22, 5, 200, 0, 0, 'D', '2024-07-31', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION JULIO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 23, 6, 200, 0, 0, 'D', '2024-08-31', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION AGOSTO-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 24, 7, 200, 0, 0, 'D', '2024-09-30', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION SETIEMBRE-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 25, 8, 200, 0, 0, 'D', '2024-10-31', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION OCTUBRE-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 26, 9, 200, 0, 0, 'D', '2024-11-30', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION NOVIEMBRE-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(3, 27, 10, 200, 0, 0, 'D', '2024-12-31', NULL, 1, '2023-12-26 21:10:32', 1, '2023-12-26 21:10:32', b'1', '190.239.221.201', '190.239.221.201', 'PENSION DICIEMBRE-2024 - 3 AÑOS INICIAL', 'KikePC', 'KikePC', 0),
(4, 32, 11, 150, 0, 0, 'D', '2024-01-06', NULL, 1, '2024-01-06 14:01:09', 1, '2024-01-06 14:01:09', b'1', 'iperror', 'iperror', 'MATRICULA-2024 - 4 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 33, 11, 150, 0, 0, 'D', '2024-01-06', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'MATRICULA-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 34, 1, 200, 0, 0, 'D', '2024-03-31', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION MARZO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 35, 2, 200, 0, 0, 'D', '2024-04-30', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION ABRIL-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 36, 3, 200, 0, 0, 'D', '2024-05-31', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION MAYO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 37, 4, 200, 0, 0, 'D', '2024-06-30', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION JUNIO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 38, 5, 200, 0, 0, 'D', '2024-07-31', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION JULIO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 39, 6, 200, 0, 0, 'D', '2024-08-31', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION AGOSTO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 40, 7, 200, 0, 0, 'D', '2024-09-30', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION SETIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 41, 8, 200, 0, 0, 'D', '2024-10-31', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION OCTUBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 42, 9, 200, 0, 0, 'D', '2024-11-30', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION NOVIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(5, 43, 10, 200, 0, 0, 'D', '2024-12-31', NULL, 1, '2024-01-06 14:05:24', 1, '2024-01-06 14:05:24', b'1', 'iperror', 'iperror', 'PENSION DICIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(6, 48, 11, 150, 0, 0, 'D', '2024-01-07', NULL, 1, '2024-01-07 08:49:10', 1, '2024-01-07 08:49:10', b'1', 'iperror', 'iperror', 'MATRICULA-2024 - 4 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 49, 11, 150, 0, 0, 'D', '2024-01-07', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'MATRICULA-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 50, 1, 200, 0, 0, 'D', '2024-03-31', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION MARZO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 51, 2, 200, 0, 0, 'D', '2024-04-30', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION ABRIL-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 52, 3, 200, 0, 0, 'D', '2024-05-31', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION MAYO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 53, 4, 200, 0, 0, 'D', '2024-06-30', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION JUNIO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 54, 5, 200, 0, 0, 'D', '2024-07-31', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION JULIO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 55, 6, 200, 0, 0, 'D', '2024-08-31', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION AGOSTO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 56, 7, 200, 0, 0, 'D', '2024-09-30', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION SETIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 57, 8, 200, 0, 0, 'D', '2024-10-31', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION OCTUBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 58, 9, 200, 0, 0, 'D', '2024-11-30', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION NOVIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(7, 59, 10, 200, 0, 0, 'D', '2024-12-31', NULL, 1, '2024-01-07 09:54:04', 1, '2024-01-07 09:54:04', b'1', 'iperror', 'iperror', 'PENSION DICIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 64, 11, 150, 0, 0, 'D', '2024-01-07', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'MATRICULA-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 65, 1, 200, 0, 0, 'D', '2024-03-31', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION MARZO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 66, 2, 200, 0, 0, 'D', '2024-04-30', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION ABRIL-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 67, 3, 200, 0, 0, 'D', '2024-05-31', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION MAYO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 68, 4, 200, 0, 0, 'D', '2024-06-30', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION JUNIO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 69, 5, 200, 0, 0, 'D', '2024-07-31', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION JULIO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 70, 6, 200, 0, 0, 'D', '2024-08-31', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION AGOSTO-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 71, 7, 200, 0, 0, 'D', '2024-09-30', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION SETIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 72, 8, 200, 0, 0, 'D', '2024-10-31', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION OCTUBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 73, 9, 200, 0, 0, 'D', '2024-11-30', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION NOVIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(8, 74, 10, 200, 0, 0, 'D', '2024-12-31', NULL, 1, '2024-01-07 10:06:01', 1, '2024-01-07 10:06:01', b'1', 'iperror', 'iperror', 'PENSION DICIEMBRE-2024 - 3 AÑOS INICIAL', 'hosterror', 'hosterror', 0),
(9, 75, 11, 200, 0, 0, 'D', '2024-01-10', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'MATRICULA-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 76, 1, 250, 0, 0, 'D', '2024-03-31', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION MARZO-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 77, 2, 250, 0, 0, 'D', '2024-04-30', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION ABRIL-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 78, 3, 250, 0, 0, 'D', '2024-05-31', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION MAYO-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 79, 4, 250, 0, 0, 'D', '2024-06-30', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION JUNIO-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 80, 5, 250, 0, 0, 'D', '2024-07-31', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION JULIO-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 81, 6, 250, 0, 0, 'D', '2024-08-31', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION AGOSTO-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 82, 7, 250, 0, 0, 'D', '2024-09-30', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION SETIEMBRE-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 83, 8, 250, 0, 0, 'D', '2024-10-31', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION OCTUBRE-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 84, 9, 250, 0, 0, 'D', '2024-11-30', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION NOVIEMBRE-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0),
(9, 85, 10, 250, 0, 0, 'D', '2024-12-31', NULL, 1, '2024-01-10 21:32:08', 1, '2024-01-10 21:32:08', b'1', 'iperror', 'iperror', 'PENSION DICIEMBRE-2024 - PRIMERO PRIMARIA', 'hosterror', 'hosterror', 0);

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `formpago`
--

CREATE TABLE `formpago` (
  `codiFormPago` tinyint(4) NOT NULL,
  `nombFormPago` varchar(50) DEFAULT NULL,
  `actiFormPago` bit(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `formpago`
--

INSERT INTO `formpago` (`codiFormPago`, `nombFormPago`, `actiFormPago`) VALUES
(1, 'EFECTIVO', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `grado`
--

CREATE TABLE `grado` (
  `codiNive` tinyint(4) DEFAULT NULL,
  `codiGrad` tinyint(4) NOT NULL,
  `nombGrad` varchar(50) DEFAULT NULL,
  `actiGrado` bit(1) DEFAULT b'1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `grado`
--

INSERT INTO `grado` (`codiNive`, `codiGrad`, `nombGrad`, `actiGrado`) VALUES
(1, 1, '3 AÑOS', b'1'),
(1, 2, '4 AÑOS', b'1'),
(1, 3, '5 AÑOS', b'1'),
(2, 4, 'PRIMERO', b'1'),
(2, 5, 'SEGUNDO', b'1'),
(2, 6, 'TERCERO', b'1'),
(2, 7, 'CUARTO', b'1'),
(2, 8, 'QUINTO', b'1'),
(2, 9, 'SEXTO', b'1'),
(3, 10, 'PRIMERO', b'1'),
(3, 11, 'SEGUNDO', b'1'),
(3, 12, 'TERCERO', b'1'),
(3, 13, 'CUARTO', b'1'),
(3, 14, 'QUINTO', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `menu`
--

CREATE TABLE `menu` (
  `codiMenu` int(11) NOT NULL,
  `padreMenu` int(11) DEFAULT NULL,
  `urlMenu` varchar(500) DEFAULT NULL,
  `urlTitulo` varchar(80) DEFAULT NULL,
  `urlMenuParam` varchar(300) DEFAULT NULL,
  `actiMenu` bit(1) DEFAULT NULL,
  `codiPagi` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `mes`
--

CREATE TABLE `mes` (
  `codiMes` tinyint(4) NOT NULL,
  `nombMes` varchar(20) DEFAULT NULL,
  `actiMes` bit(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `mes`
--

INSERT INTO `mes` (`codiMes`, `nombMes`, `actiMes`) VALUES
(1, 'ENERO', b'1'),
(2, 'FEBRERO', b'1'),
(3, 'MARZO', b'1'),
(4, 'ABRIL', b'1'),
(5, 'MAYO', b'1'),
(6, 'JUNIO', b'1'),
(7, 'JULIO', b'1'),
(8, 'AGOSTO', b'1'),
(9, 'SETIEMBRE', b'1'),
(10, 'OCTUBRE', b'1'),
(11, 'NOVIEMBRE', b'1'),
(12, 'DICIEMBRE', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `nivel`
--

CREATE TABLE `nivel` (
  `codiNive` tinyint(4) NOT NULL,
  `nombNive` varchar(50) DEFAULT NULL,
  `actiNive` bit(1) DEFAULT b'1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `nivel`
--

INSERT INTO `nivel` (`codiNive`, `nombNive`, `actiNive`) VALUES
(1, 'INICIAL', b'1'),
(2, 'PRIMARIA', b'1'),
(3, 'SECUNDARIA', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `pagina`
--

CREATE TABLE `pagina` (
  `codiPagi` int(11) NOT NULL,
  `nombPagi` varchar(20) DEFAULT NULL,
  `actiPagi` bit(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `pagina`
--

INSERT INTO `pagina` (`codiPagi`, `nombPagi`, `actiPagi`) VALUES
(1, 'NINGUNA', b'1'),
(2, 'login', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `paginarol`
--

CREATE TABLE `paginarol` (
  `codiPagi` int(11) DEFAULT NULL,
  `codiRole` int(11) DEFAULT NULL,
  `codiPagiRol` int(11) NOT NULL,
  `actiPagiRol` char(18) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `paginarol`
--

INSERT INTO `paginarol` (`codiPagi`, `codiRole`, `codiPagiRol`, `actiPagiRol`) VALUES
(1, 1, 1, '1'),
(2, 1, 2, '1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `parametro`
--

CREATE TABLE `parametro` (
  `codiPara` int(11) NOT NULL,
  `nombPara` varchar(20) NOT NULL,
  `valuPara` varchar(30) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `parametro`
--

INSERT INTO `parametro` (`codiPara`, `nombPara`, `valuPara`) VALUES
(1, 'EMPRESA', 'CORPORACION SAC'),
(2, 'COLEGIO', 'NICOLA TESLA'),
(3, 'DIRECCION', 'AV. INDUSTRIAL 565'),
(4, 'CELULAR', '982065304'),
(5, 'CORREO', 'soporte@gmail.com');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `recibo`
--

CREATE TABLE `recibo` (
  `codiReci` int(11) NOT NULL,
  `codiFormPago` tinyint(4) DEFAULT NULL,
  `codiSeri` tinyint(4) NOT NULL,
  `numeReci` int(11) DEFAULT NULL,
  `montReci` float DEFAULT NULL,
  `montReciText` text DEFAULT NULL,
  `numeOper` varchar(15) DEFAULT NULL,
  `estdReci` char(1) DEFAULT NULL,
  `codiUsuaAlta` int(11) DEFAULT NULL,
  `fechRegiAlta` datetime DEFAULT NULL,
  `codiUsuaModi` int(11) DEFAULT NULL,
  `fechRegiModi` datetime DEFAULT NULL,
  `actiReci` bit(1) DEFAULT NULL,
  `ipRegiAlta` varchar(20) DEFAULT NULL,
  `ipRegiModi` varchar(20) DEFAULT NULL,
  `codiSubCuot` int(11) DEFAULT NULL,
  `hostRegiAlta` varchar(20) DEFAULT NULL,
  `hostRegiModi` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `rol`
--

CREATE TABLE `rol` (
  `codiRole` int(11) NOT NULL,
  `nombRole` varchar(20) DEFAULT NULL,
  `actiRole` bit(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `rol`
--

INSERT INTO `rol` (`codiRole`, `nombRole`, `actiRole`) VALUES
(1, 'Administrador', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `seccion`
--

CREATE TABLE `seccion` (
  `codiSecc` tinyint(4) NOT NULL,
  `nombSecc` varchar(50) DEFAULT NULL,
  `actiSecc` bit(1) DEFAULT b'1'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

--
-- Volcado de datos para la tabla `seccion`
--

INSERT INTO `seccion` (`codiSecc`, `nombSecc`, `actiSecc`) VALUES
(1, 'A', b'1'),
(2, 'B', b'1');

-- --------------------------------------------------------

--
-- Estructura de tabla para la tabla `usuario`
--

CREATE TABLE `usuario` (
  `codiUsua` int(11) NOT NULL,
  `ndniUsua` varchar(15) NOT NULL,
  `logiUsua` varchar(50) NOT NULL,
  `passUsua` varchar(80) NOT NULL,
  `niveUsua` int(11) NOT NULL,
  `actiUsua` bit(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Volcado de datos para la tabla `usuario`
--

INSERT INTO `usuario` (`codiUsua`, `ndniUsua`, `logiUsua`, `passUsua`, `niveUsua`, `actiUsua`) VALUES
(1, '40801418', 'kike', 'T9u7dzBdi+w=', 1, b'1');

--
-- Índices para tablas volcadas
--

--
-- Indices de la tabla `usuario`
--
ALTER TABLE `usuario`
  ADD PRIMARY KEY (`codiUsua`);

--
-- AUTO_INCREMENT de las tablas volcadas
--

--
-- AUTO_INCREMENT de la tabla `usuario`
--
ALTER TABLE `usuario`
  MODIFY `codiUsua` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
