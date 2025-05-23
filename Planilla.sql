USE [master]
GO
/****** Object:  Database [Planilla]    Script Date: 28/04/2025 21:11:27 ******/
CREATE DATABASE [Planilla]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'Planilla', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Planilla.mdf' , SIZE = 8192KB , MAXSIZE = UNLIMITED, FILEGROWTH = 65536KB )
 LOG ON 
( NAME = N'Planilla_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\Planilla_log.ldf' , SIZE = 8192KB , MAXSIZE = 2048GB , FILEGROWTH = 65536KB )
 WITH CATALOG_COLLATION = DATABASE_DEFAULT, LEDGER = OFF
GO
ALTER DATABASE [Planilla] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [Planilla].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [Planilla] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [Planilla] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [Planilla] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [Planilla] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [Planilla] SET ARITHABORT OFF 
GO
ALTER DATABASE [Planilla] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [Planilla] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [Planilla] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [Planilla] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [Planilla] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [Planilla] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [Planilla] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [Planilla] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [Planilla] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [Planilla] SET  DISABLE_BROKER 
GO
ALTER DATABASE [Planilla] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [Planilla] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [Planilla] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [Planilla] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [Planilla] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [Planilla] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [Planilla] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [Planilla] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [Planilla] SET  MULTI_USER 
GO
ALTER DATABASE [Planilla] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [Planilla] SET DB_CHAINING OFF 
GO
ALTER DATABASE [Planilla] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [Planilla] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [Planilla] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [Planilla] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [Planilla] SET QUERY_STORE = ON
GO
ALTER DATABASE [Planilla] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [Planilla]
GO
/****** Object:  Table [dbo].[Usuario]    Script Date: 28/04/2025 21:11:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Usuario](
	[codiUsua] [int] IDENTITY(1,1) NOT NULL,
	[logiUsua] [varchar](100) NULL,
	[passUsua] [varchar](100) NULL,
	[ndniUsua] [varchar](8) NULL,
	[nombUsua] [varchar](100) NULL,
	[celuUsua] [varchar](9) NULL,
	[codiRol] [int] NULL,
	[actvUsua] [bit] NULL,
 CONSTRAINT [PK_usuario] PRIMARY KEY CLUSTERED 
(
	[codiUsua] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[Usuario] ON 

INSERT [dbo].[Usuario] ([codiUsua], [logiUsua], [passUsua], [ndniUsua], [nombUsua], [celuUsua], [codiRol], [actvUsua]) VALUES (1, N'kike', N'PwVl7PYPDavdLSqeb3FQBA==', N'1234567', N'kike', N'123456789', 1, 1)
SET IDENTITY_INSERT [dbo].[Usuario] OFF
GO
USE [master]
GO
ALTER DATABASE [Planilla] SET  READ_WRITE 
GO
