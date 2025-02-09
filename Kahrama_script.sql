USE [CareSource_GulamDB]
GO
/****** Object:  FullTextCatalog [FTC_PhoneNumber_CustomDNCMaruti]    Script Date: 18-09-2024 7.30.43 PM ******/
CREATE FULLTEXT CATALOG [FTC_PhoneNumber_CustomDNCMaruti] WITH ACCENT_SENSITIVITY = OFF
GO
/****** Object:  FullTextCatalog [FTC_PhoneNumber_Global_DNC]    Script Date: 18-09-2024 7.30.43 PM ******/
CREATE FULLTEXT CATALOG [FTC_PhoneNumber_Global_DNC] WITH ACCENT_SENSITIVITY = OFF
GO
/****** Object:  UserDefinedTableType [dbo].[IntTableType]    Script Date: 18-09-2024 7.30.43 PM ******/
CREATE TYPE [dbo].[IntTableType] AS TABLE(
	[Id] [int] NULL
)
GO
/****** Object:  UserDefinedFunction [dbo].[CampaignListState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE function [dbo].[CampaignListState](@list_id int) returns bit as 
begin
	if(exists(select ListId from CampaignContact_List where CampaignList_Id = @list_id and IsActive = 1 and dbo.ListState(ListId) = 1 ))
	begin
		return 1
	end
	return 0
end













GO
/****** Object:  UserDefinedFunction [dbo].[CheckIfCampaignMapsInProcessingState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create function [dbo].[CheckIfCampaignMapsInProcessingState](@CampaignId int)
returns bit
as begin
If(exists(select * from  CampaignContact_List map  where map.Status in (2,5) and map.CampaignId = @CampaignId ))
begin
return 1;
end
If(exists(select * from ContactMapAppendConfig ap where ap.Status=2 and ap.CampaignId = @CampaignId ))
begin
return 1;
end
If(exists(select * from  ContactMapGroup gp  where gp.Status in (2,1,5) and gp.CampaignId = @CampaignId ))
begin
return 1;
end
return 0;
end





GO
/****** Object:  UserDefinedFunction [dbo].[CheckIfMapIsStopped]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE function [dbo].[CheckIfMapIsStopped](@MapId int,@CampaignId int)
returns bit
as begin
If(exists(select * from CampaignContact_List map where map.CampaignList_Id = @MapId and map.Status=6 and map.CampaignId = @CampaignId))
begin
return 1;
end
If(exists(select * from ContactMapAppendConfig ap where ap.ParentMapId = @MapId and ap.Status=6 and ap.CampaignId = @CampaignId))
begin
return 1;
end
If(exists(select * from ContactMapGroup gp where gp.Status=6 and gp.CampaignId = @CampaignId))
begin
return 1;
end
return 0;
end





GO
/****** Object:  UserDefinedFunction [dbo].[CheckIfMapsInPausedState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[CheckIfMapsInPausedState](@ListId int,@CampaignId int)
returns bit
as begin
If(exists(select * from Contact_List cl inner join CampaignContact_List map on map.ListId=cl.Id where map.Status in (5,2) and map.CampaignId = @CampaignId and cl.Id=cast(@ListId as nvarchar) ))
begin
return 1;
end
If(exists(select *  from Contact_List cl inner join ContactMapAppendConfig ap on  ap.AppendedListId=cl.Id where ap.Status=2 and ap.CampaignId = @CampaignId  and cl.Id=cast(@ListId as nvarchar)))
begin
return 1;
end
If(exists(select * from Contact_List cl inner join ContactMapGroup gp on  gp.ListId=cl.Id where gp.Status in (5,2) and gp.CampaignId = @CampaignId and cl.Id=cast(@ListId as nvarchar)))
begin
return 1;
end
return 0;
end




GO
/****** Object:  UserDefinedFunction [dbo].[CheckIfMapsInProcessingState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[CheckIfMapsInProcessingState](@ListId int,@CampaignId int)
returns bit
as begin
If(exists(select * from Contact_List cl inner join CampaignContact_List map on map.ListId=cl.Id where map.Status in (2,1) and map.CampaignId = @CampaignId and cl.Id=cast(@ListId as nvarchar) ))
begin
return 1;
end
If(exists(select * from Contact_List cl inner join ContactMapAppendConfig ap on  ap.AppendedListId=cl.Id where ap.Status=2 and ap.CampaignId = @CampaignId  and cl.Id=cast(@ListId as nvarchar)))
begin
return 1;
end
If(exists(select * from Contact_List cl inner join ContactMapGroup gp on  gp.ListId=cl.Id where gp.Status in (2,1) and gp.CampaignId = @CampaignId and cl.Id=cast(@ListId as nvarchar)))
begin
return 1;
end
return 0;
end




GO
/****** Object:  UserDefinedFunction [dbo].[CompareXml]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[CompareXml]
(
    @xml1 XML,
    @xml2 XML
)
RETURNS INT
AS 
BEGIN
    DECLARE @ret INT
    SELECT @ret = 0


    -- -------------------------------------------------------------
    -- If one of the arguments is NULL then we assume that they are
    -- not equal. 
    -- -------------------------------------------------------------
    IF @xml1 IS NULL OR @xml2 IS NULL 
    BEGIN
        RETURN 1
    END

    -- -------------------------------------------------------------
    -- Match the name of the elements 
    -- -------------------------------------------------------------
    IF  (SELECT @xml1.value('(local-name((/*)[1]))','VARCHAR(MAX)')) 
        <> 
        (SELECT @xml2.value('(local-name((/*)[1]))','VARCHAR(MAX)'))
    BEGIN
        RETURN 1
    END

     ---------------------------------------------------------------
     --Match the value of the elements
     ---------------------------------------------------------------
    IF((@xml1.query('count(/*)').value('.','INT') = 1) AND (@xml2.query('count(/*)').value('.','INT') = 1))
    BEGIN
    DECLARE @elValue1 VARCHAR(MAX), @elValue2 VARCHAR(MAX)

    SELECT
        @elValue1 = @xml1.value('((/*)[1])','VARCHAR(MAX)'),
        @elValue2 = @xml2.value('((/*)[1])','VARCHAR(MAX)')

    IF  @elValue1 <> @elValue2
    BEGIN
        RETURN 1
    END
    END

    -- -------------------------------------------------------------
    -- Match the number of attributes 
    -- -------------------------------------------------------------
    DECLARE @attCnt1 INT, @attCnt2 INT
    SELECT
        @attCnt1 = @xml1.query('count(/*/@*)').value('.','INT'),
        @attCnt2 = @xml2.query('count(/*/@*)').value('.','INT')

    IF  @attCnt1 <> @attCnt2 BEGIN
        RETURN 1
    END


    -- -------------------------------------------------------------
    -- Match the attributes of attributes 
    -- Here we need to run a loop over each attribute in the 
    -- first XML element and see if the same attribut exists
    -- in the second element. If the attribute exists, we
    -- need to check if the value is the same.
    -- -------------------------------------------------------------
    DECLARE @cnt INT, @cnt2 INT
    DECLARE @attName VARCHAR(MAX)
    DECLARE @attValue VARCHAR(MAX)

    SELECT @cnt = 1

    WHILE @cnt <= @attCnt1 
    BEGIN
        SELECT @attName = NULL, @attValue = NULL
        SELECT
            @attName = @xml1.value(
                'local-name((/*/@*[sql:variable("@cnt")])[1])', 
                'varchar(MAX)'),
            @attValue = @xml1.value(
                '(/*/@*[sql:variable("@cnt")])[1]', 
                'varchar(MAX)')

        -- check if the attribute exists in the other XML document
        IF @xml2.exist(
                '(/*/@*[local-name()=sql:variable("@attName")])[1]'
            ) = 0
        BEGIN
            RETURN 1
        END

        IF  @xml2.value(
                '(/*/@*[local-name()=sql:variable("@attName")])[1]', 
                'varchar(MAX)')
            <>
            @attValue
        BEGIN
            RETURN 1
        END

        SELECT @cnt = @cnt + 1
    END

    -- -------------------------------------------------------------
    -- Match the number of child elements 
    -- -------------------------------------------------------------
    DECLARE @elCnt1 INT, @elCnt2 INT
    SELECT
        @elCnt1 = @xml1.query('count(/*/*)').value('.','INT'),
        @elCnt2 = @xml2.query('count(/*/*)').value('.','INT')


    IF  @elCnt1 <> @elCnt2
    BEGIN
        RETURN 1
    END


    -- -------------------------------------------------------------
    -- Start recursion for each child element
    -- -------------------------------------------------------------
    SELECT @cnt = 1
    SELECT @cnt2 = 1
    DECLARE @x1 XML, @x2 XML
    DECLARE @noMatch INT

    WHILE @cnt <= @elCnt1 
    BEGIN

        SELECT @x1 = @xml1.query('/*/*[sql:variable("@cnt")]')
    --RETURN CONVERT(VARCHAR(MAX),@x1)
    WHILE @cnt2 <= @elCnt2
    BEGIN
        SELECT @x2 = @xml2.query('/*/*[sql:variable("@cnt2")]')
        SELECT @noMatch = dbo.CompareXml( @x1, @x2 )
        IF @noMatch = 0 BREAK
        SELECT @cnt2 = @cnt2 + 1
    END

    SELECT @cnt2 = 1

        IF @noMatch = 1
        BEGIN
            RETURN 1
        END

        SELECT @cnt = @cnt + 1
    END

    RETURN @ret
END




GO
/****** Object:  UserDefinedFunction [dbo].[ContactListDeletable]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ContactListDeletable](@ListId int )
returns bit
as begin
If(exists(select * from Contact_List cl inner join CampaignContact_List map on map.ListId=cl.Id where map.Status in (1,2)  and cl.Id=cast(@ListId as nvarchar) ))
begin
return 1;
end
If(exists(select * from Contact_List cl inner join ContactMapAppendConfig ap on  ap.AppendedListId=cl.Id where ap.Status=2  and cl.Id=cast(@ListId as nvarchar)))
begin
return 1;
end
If(exists(select * from Contact_List cl inner join ContactMapGroup gp on  gp.ListId=cl.Id where gp.Status=2  and cl.Id=cast(@ListId as nvarchar)))
begin
return 1;
end
return 0;
end




GO
/****** Object:  UserDefinedFunction [dbo].[ContainsTest]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ContainsTest] (@phone_number nvarchar(50))    
returns bit    
as begin    
set @phone_number = '"'+ @phone_number +'"';    
if( exists(select 1 from Global_DNC where contains(PhoneNumber,@phone_number) and Status= 2 and IsActive=1))    
begin     
return 1;    
end    
return 0;    
end 



GO
/****** Object:  UserDefinedFunction [dbo].[ContainsTestExclustionList]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create  function [dbo].[ContainsTestExclustionList] (@phone_number nvarchar(50),@campaignId int)  
returns bit  
as begin  
declare @phone_number_formatted nvarchar(50);  
  
SET @phone_number_formatted = CASE WHEN (@phone_number = '' OR @phone_number IS NULL) then '"0"' ELSE @phone_number END  
  
if(exists(select 1 from CustomDNCMaruti WHERE CampaignId=CAST(@campaignId AS VARCHAR) AND  
CONTAINS(PhoneNumber, @phone_number_formatted) AND IsActive=1 AND (StartDate is NULL OR EndDate Is NULL)))  
  
begin   
return 1;  
end  
return 0;  
end  



GO
/****** Object:  UserDefinedFunction [dbo].[HolidayState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[HolidayState](@holiday_id int) returns bit as 
begin
	if(exists(select HolidayId from Holiday where HolidayId = @holiday_id and IsActive = 1))
	begin
		return 1
	end
	return 0
end













GO
/****** Object:  UserDefinedFunction [dbo].[ListState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[ListState](@list_id int) returns bit as 
begin
	if(exists(select SourceId from Contact_List where Id = @list_id and IsActive = 1 and dbo.SourceState(SourceId) = 1  ))
	begin
		return 1
	end
	return 0
end











GO
/****** Object:  UserDefinedFunction [dbo].[PreviewCampaignListState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[PreviewCampaignListState](@list_id int) returns bit as 
begin
	if(exists(select ListId from PreviewCampaignContact_List where CampaignList_Id = @list_id and IsActive = 1 and dbo.ListState(ListId) = 1 ))
	begin
		return 1
	end
	return 0
end









GO
/****** Object:  UserDefinedFunction [dbo].[SourceState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[SourceState](@source_id int) returns bit as
begin
	if(exists(select Id from ImportList_Source where Id = @source_id and IsActive = 1))
	begin
		return 1
	end
	return 0
end











GO
/****** Object:  UserDefinedFunction [dbo].[Split_demo]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create FUNCTION [dbo].[Split_demo](@input AS Varchar(4000) )

RETURNS

      @Result TABLE(Value INT)

AS

BEGIN

      DECLARE @str VARCHAR(20)

      DECLARE @ind Int

      IF(@input is not null)

      BEGIN

            SET @ind = CharIndex(',',@input)

            WHILE @ind > 0

            BEGIN

                  SET @str = SUBSTRING(@input,1,@ind-1)

                  SET @input = SUBSTRING(@input,@ind+1,LEN(@input)-@ind)

                  INSERT INTO @Result values (@str)

                  SET @ind = CharIndex(',',@input)

            END

            SET @str = @input

            INSERT INTO @Result values (@str)

      END

      RETURN

END 




GO
/****** Object:  UserDefinedFunction [dbo].[TenantState]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[TenantState](@tenant_id int) returns bit as 
begin
	if(exists(select Id from Tenants where Id = @tenant_id and IsActive = 1))
	begin
		return 1
	end
	return 0
end











GO
/****** Object:  UserDefinedFunction [dbo].[GetCallResultsFromXml]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[GetCallResultsFromXml](@xml_data xml)
returns table
as return 
select CallResult.query('./text()').value('.','int') as CallDispositions from @xml_data.nodes('/callResults/callResult') as CallResults(CallResult)




GO
/****** Object:  Table [dbo].[AgentCallDetails]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgentCallDetails](
	[CallID] [uniqueidentifier] NOT NULL,
	[State] [int] NOT NULL,
	[WrapupReasonCode] [nvarchar](50) NULL,
	[CreatedOn] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[CallID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AgentScripts]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgentScripts](
	[AgentScriptID] [int] IDENTITY(1000000,1) NOT NULL,
	[AgentScriptName] [nvarchar](100) NOT NULL,
	[ScriptBody] [nvarchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Enable] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
 CONSTRAINT [PK__AgentScr__BC0A38554D2A7347] PRIMARY KEY CLUSTERED 
(
	[AgentScriptID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__AgentScr__9DC709855F492382] UNIQUE NONCLUSTERED 
(
	[AgentScriptName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[AreaCode_list]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AreaCode_list](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AreaCode] [varchar](30) NULL,
	[TimeZone] [varchar](100) NULL,
	[Region] [varchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Audit_Trail]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Audit_Trail](
	[AuditId] [int] IDENTITY(1,1) NOT NULL,
	[ActionName] [nvarchar](255) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[DateTime] [datetime] NOT NULL,
	[UserId] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[Details] [xml] NULL,
 CONSTRAINT [PK_Audit_Trail] PRIMARY KEY CLUSTERED 
(
	[AuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[BulkCallback]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[BulkCallback](
	[BulkId] [int] IDENTITY(1,1) NOT NULL,
	[FilePath] [nvarchar](300) NOT NULL,
	[OverwriteData] [bit] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[AgentSkillTargetId] [int] NOT NULL,
	[Delimiter] [char](1) NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[BulkId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CampaignContact_List]    Script Date: 18-09-2024 7.30.43 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CampaignContact_List](
	[CampaignList_Id] [int] IDENTITY(1,1) NOT NULL,
	[CampaignId] [int] NOT NULL,
	[ListId] [int] NOT NULL,
	[TargetCountry] [nvarchar](4) NOT NULL,
	[ScheduleStart] [datetime] NULL,
	[TimeZone] [nvarchar](255) NULL,
	[Recurrence] [int] NOT NULL,
	[Recurrence_Interval] [numeric](10, 2) NULL,
	[RecurrenceUnit] [int] NOT NULL,
	[FilterDuplicate] [bit] NULL,
	[FilterDNC] [bit] NULL,
	[KeepHeaders] [bit] NULL,
	[AccountNumber] [nvarchar](100) NULL,
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[Phone01] [nvarchar](100) NOT NULL,
	[Phone02] [nvarchar](100) NULL,
	[Phone03] [nvarchar](100) NULL,
	[Phone04] [nvarchar](100) NULL,
	[Phone05] [nvarchar](100) NULL,
	[Phone06] [nvarchar](100) NULL,
	[Phone07] [nvarchar](100) NULL,
	[Phone08] [nvarchar](100) NULL,
	[Phone09] [nvarchar](100) NULL,
	[Phone10] [nvarchar](100) NULL,
	[TimeZone_bias] [nvarchar](100) NULL,
	[DstObserve] [nvarchar](100) NULL,
	[OverwriteData] [bit] NOT NULL,
	[DuplicateRules] [xml] NULL,
	[TenantId] [int] NOT NULL,
	[Status] [int] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
	[ExtraDetails] [xml] NULL,
	[FutureUseVarchar1] [nvarchar](255) NULL,
	[FutureUseVarchar2] [nvarchar](255) NULL,
	[FutureUseVarchar3] [nvarchar](255) NULL,
	[FutureUseVarchar4] [nvarchar](255) NULL,
	[FutureUseVarchar5] [nvarchar](255) NULL,
	[FutureUseVarchar6] [nvarchar](255) NULL,
	[FutureUseVarchar7] [nvarchar](255) NULL,
	[FutureUseVarchar8] [nvarchar](255) NULL,
	[FutureUseVarchar9] [nvarchar](255) NULL,
	[FutureUseVarchar10] [nvarchar](255) NULL,
	[FutureUseVarchar11] [nvarchar](255) NULL,
	[FutureUseVarchar12] [nvarchar](255) NULL,
	[FutureUseVarchar13] [nvarchar](255) NULL,
	[FutureUseVarchar14] [nvarchar](255) NULL,
	[FutureUseVarchar15] [nvarchar](255) NULL,
	[RequestType] [nvarchar](25) NOT NULL,
	[Filters] [xml] NULL,
	[DialingPriority] [int] NULL,
	[ParentContactMap] [int] NULL,
	[LastStatus] [int] NULL,
	[FutureUseVarchar16] [varchar](255) NULL,
 CONSTRAINT [PK__Campaign__DE91FE4A4A18FC72] PRIMARY KEY CLUSTERED 
(
	[CampaignList_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CampaignExtraDetails]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CampaignExtraDetails](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CampaignId] [int] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Details] [xml] NOT NULL,
	[DealerId] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NOT NULL,
	[Areacodes] [nvarchar](100) NULL,
	[AgentScriptID] [int] NULL,
	[CampaignPrefix] [nvarchar](50) NULL,
 CONSTRAINT [PK_CampaignExtraDetails] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__Campaign__3DB73EE62116E6DF] UNIQUE NONCLUSTERED 
(
	[CampaignId] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CampaignHoliday]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CampaignHoliday](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[HolidayId] [int] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[Status] [int] NULL,
	[TenantId] [int] NULL,
	[DateTime] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[PreviousState] [bit] NULL,
	[CampaignType] [varchar](255) NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[HolidayId] ASC,
	[CampaignId] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CampaignMultipleContact_List]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CampaignMultipleContact_List](
	[MapId] [int] IDENTITY(1,1) NOT NULL,
	[ListId] [int] NOT NULL,
	[CampaignListConfig] [xml] NOT NULL,
	[TargetCountry] [nvarchar](4) NOT NULL,
	[ScheduleStart] [datetime] NULL,
	[TimeZone] [nvarchar](255) NULL,
	[Recurrence] [int] NOT NULL,
	[Recurrence_Interval] [numeric](10, 2) NULL,
	[RecurrenceUnit] [int] NOT NULL,
	[FilterDuplicate] [bit] NULL,
	[FilterDNC] [bit] NULL,
	[KeepHeaders] [bit] NULL,
	[AccountNumber] [nvarchar](100) NULL,
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[Phone01] [nvarchar](100) NOT NULL,
	[Phone02] [nvarchar](100) NULL,
	[Phone03] [nvarchar](100) NULL,
	[Phone04] [nvarchar](100) NULL,
	[Phone05] [nvarchar](100) NULL,
	[Phone06] [nvarchar](100) NULL,
	[Phone07] [nvarchar](100) NULL,
	[Phone08] [nvarchar](100) NULL,
	[Phone09] [nvarchar](100) NULL,
	[Phone10] [nvarchar](100) NULL,
	[TimeZone_bias] [nvarchar](100) NULL,
	[DstObserve] [nvarchar](100) NULL,
	[OverwriteData] [bit] NOT NULL,
	[DuplicateRules] [xml] NULL,
	[TenantId] [int] NOT NULL,
	[Status] [int] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ExtraDetails] [xml] NULL,
	[DealerId] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CBMConfig]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CBMConfig](
	[CampaignId] [int] NOT NULL,
	[MaximumAttempts] [int] NOT NULL,
	[Level] [int] NOT NULL,
	[IdentifierField] [nvarchar](20) NULL,
	[CallResultMap] [xml] NULL,
	[WrapupMap] [xml] NULL,
	[TenantId] [int] NOT NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL,
 CONSTRAINT [PK_CBMConfig] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[CampaignId] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ClicktoCallData]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ClicktoCallData](
	[ImportId] [uniqueidentifier] NOT NULL,
	[PhoneNumber] [numeric](20, 0) NOT NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[Email] [nvarchar](50) NULL,
	[CreatedOn] [datetime] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ImportId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Contact_List]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Contact_List](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](250) NULL,
	[Purpose] [int] NOT NULL,
	[Details] [xml] NULL,
	[SourceId] [int] NOT NULL,
	[Filters] [xml] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NULL,
	[DealerId] [int] NOT NULL,
	[AutoGenerated] [bit] NULL,
 CONSTRAINT [PK__Contact___3214EC07436BFEE3] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ContactList_ImportStatus]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContactList_ImportStatus](
	[CampaignList_Id] [int] IDENTITY(1,1) NOT NULL,
	[ListId] [int] NOT NULL,
	[TotalRecords] [int] NOT NULL,
	[TotalRecordImported] [int] NOT NULL,
	[TotalDncFiltered] [int] NULL,
	[TotalDuplicateFiltered] [int] NULL,
	[TotalInvalid] [int] NULL,
	[FinishIndex] [nvarchar](1000) NULL,
	[PreProcessedOn] [datetime] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[LastAttemptedOn] [datetime] NULL,
	[LastImportFailedRecords] [int] NULL,
	[Status] [int] NOT NULL,
 CONSTRAINT [PK__ContactL__DE91FE4A284DF453] PRIMARY KEY CLUSTERED 
(
	[CampaignList_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ContactListSequence]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContactListSequence](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[TenantId] [int] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[SourceId] [int] NOT NULL,
	[TemplatePath] [nvarchar](max) NOT NULL,
	[Delimiter] [nvarchar](1) NOT NULL,
	[FileNameFormat] [nvarchar](max) NOT NULL,
	[PlaceholderMap] [xml] NULL,
	[HeaderMap] [xml] NULL,
	[MaximumDailyIterations] [int] NOT NULL,
	[IntervalInMinutes] [numeric](10, 2) NOT NULL,
	[StartDateTime] [datetime] NULL,
	[TimeZone] [nvarchar](255) NOT NULL,
	[TargetCountry] [nvarchar](4) NOT NULL,
	[NextIterationDate] [datetime] NULL,
	[Status] [int] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NULL,
	[Interval] [numeric](10, 2) NULL,
	[IntervalUnit] [int] NOT NULL,
	[Headers] [bit] NULL,
	[Filters] [xml] NULL,
	[DealerId] [int] NOT NULL,
	[FilterDuplicate] [bit] NULL,
	[DuplicateRules] [xml] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ContactListSequenceIteration]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContactListSequenceIteration](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SequenceId] [int] NOT NULL,
	[MapId] [int] NOT NULL,
	[ListId] [int] NOT NULL,
	[PlaceholderMap] [xml] NULL,
	[AutogeneratedFileName] [nvarchar](max) NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsFileRead] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ContactMapAppendConfig]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContactMapAppendConfig](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CampaignId] [int] NOT NULL,
	[ParentMapId] [int] NOT NULL,
	[AppendedListId] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ContactMapGroup]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContactMapGroup](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[CampaignId] [int] NOT NULL,
	[ListId] [int] NOT NULL,
	[TargetCountry] [nvarchar](4) NOT NULL,
	[ScheduleStart] [datetime] NULL,
	[TimeZone] [nvarchar](255) NULL,
	[Recurrence] [int] NULL,
	[RecurrenceInterval] [numeric](10, 2) NULL,
	[RecurrenceUnit] [int] NULL,
	[FilterDuplicate] [bit] NULL,
	[FilterDNC] [bit] NULL,
	[KeepHeaders] [bit] NULL,
	[DialingPriority] [int] NULL,
	[ParentId] [int] NULL,
	[Status] [int] NULL,
	[GroupDetails] [xml] NULL,
	[Phone01] [nvarchar](100) NOT NULL,
	[AccountNumber] [nvarchar](100) NULL,
	[FirstName] [nvarchar](100) NULL,
	[LastName] [nvarchar](100) NULL,
	[Phone02] [nvarchar](100) NULL,
	[Phone03] [nvarchar](100) NULL,
	[Phone04] [nvarchar](100) NULL,
	[Phone05] [nvarchar](100) NULL,
	[Phone06] [nvarchar](100) NULL,
	[Phone07] [nvarchar](100) NULL,
	[Phone08] [nvarchar](100) NULL,
	[Phone09] [nvarchar](100) NULL,
	[Phone10] [nvarchar](100) NULL,
	[TimeZoneBias] [nvarchar](100) NULL,
	[DstObserved] [nvarchar](100) NULL,
	[OverwriteData] [bit] NOT NULL,
	[DuplicateRules] [xml] NULL,
	[ExtraDetails] [xml] NULL,
	[FutureUseVarchar1] [nvarchar](255) NULL,
	[FutureUseVarchar2] [nvarchar](255) NULL,
	[FutureUseVarchar3] [nvarchar](255) NULL,
	[FutureUseVarchar4] [nvarchar](255) NULL,
	[FutureUseVarchar5] [nvarchar](255) NULL,
	[FutureUseVarchar6] [nvarchar](255) NULL,
	[FutureUseVarchar7] [nvarchar](255) NULL,
	[FutureUseVarchar8] [nvarchar](255) NULL,
	[FutureUseVarchar9] [nvarchar](255) NULL,
	[FutureUseVarchar10] [nvarchar](255) NULL,
	[FutureUseVarchar11] [nvarchar](255) NULL,
	[FutureUseVarchar12] [nvarchar](255) NULL,
	[FutureUseVarchar13] [nvarchar](255) NULL,
	[FutureUseVarchar14] [nvarchar](255) NULL,
	[FutureUseVarchar15] [nvarchar](255) NULL,
	[Filters] [xml] NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ContactMapGroupIteration]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContactMapGroupIteration](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[GroupId] [int] NULL,
	[MapId] [int] NULL,
	[CalculatedThreshold] [numeric](10, 2) NULL,
	[CalculatedThresholdType] [int] NULL,
	[TotalRecords] [int] NULL,
	[Details] [xml] NOT NULL,
	[Status] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CountryCodes]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CountryCodes](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](300) NOT NULL,
	[Code] [nvarchar](4) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Name] ASC,
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Name] ASC,
	[Code] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CustomDNC]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomDNC](
	[DNCId] [int] IDENTITY(1000,1) NOT NULL,
	[PhoneNumber] [nvarchar](255) NOT NULL,
	[CampaignId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DNCId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[CampaignId] ASC,
	[PhoneNumber] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CustomDNCMapTable]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomDNCMapTable](
	[DNCMapId] [int] IDENTITY(1000,1) NOT NULL,
	[FilePath] [nvarchar](255) NOT NULL,
	[CampaignId] [int] NOT NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[Recurrence] [int] NOT NULL,
	[RecurrenceInterval] [numeric](10, 2) NULL,
	[NextIterationDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DealerId] [int] NOT NULL,
	[status] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[CustomDNCMaruti]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CustomDNCMaruti](
	[DNCId] [int] IDENTITY(1000,1) NOT NULL,
	[PhoneNumber] [nvarchar](255) NOT NULL,
	[CampaignId] [int] NOT NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NULL,
	[status] [int] NOT NULL,
	[Recurrence] [int] NOT NULL,
	[RecurrenceInterval] [numeric](10, 2) NULL,
	[NextIterationDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DealerId] [int] NOT NULL,
	[rowguid] [uniqueidentifier] ROWGUIDCOL  NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DNCId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DataDump_LastRecoveryKey]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataDump_LastRecoveryKey](
	[TenantId] [int] NOT NULL,
	[RecoveryKey] [decimal](18, 0) NOT NULL,
	[LinkedServer] [nvarchar](100) NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SecondaryLinkedServer] [nvarchar](100) NULL,
 CONSTRAINT [PK_DataDump_LastRecoveryKey] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DataDump_LastRecoveryKey_TCD]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DataDump_LastRecoveryKey_TCD](
	[TenantId] [int] NOT NULL,
	[RecoveryKey] [decimal](18, 0) NOT NULL,
	[LinkedServer] [nvarchar](100) NULL,
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[SecondaryLinkedServer] [nvarchar](100) NULL,
 CONSTRAINT [PK_DataDump_LastRecoveryKey1] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Dealer]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Dealer](
	[DealerId] [int] IDENTITY(1,1) NOT NULL,
	[DealerName] [nvarchar](50) NOT NULL,
	[TenantId] [int] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[Dealercode] [nvarchar](100) NOT NULL,
	[Status] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[DealerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Dealercode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[DealerName] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[DealerName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DealerExtraDetails]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DealerExtraDetails](
	[MapId] [int] IDENTITY(1,1) NOT NULL,
	[DealerId] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[AssignedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NULL,
	[SkillTargetID] [int] NOT NULL,
	[EnterpriseName] [nvarchar](255) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[MapId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DetailsIndex_available]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DetailsIndex_available](
	[TableName] [sysname] NOT NULL,
	[IndexName] [sysname] NULL,
	[Index_id] [int] NOT NULL,
	[Column_id] [int] NOT NULL,
	[coumnNmae] [sysname] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DNC_Test]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DNC_Test](
	[Id] [uniqueidentifier] NULL,
	[PhoneNumber] [nvarchar](255) NULL,
	[IsActive] [bit] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[DNCRule]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[DNCRule](
	[DNCId] [int] IDENTITY(1000,1) NOT NULL,
	[DNCName] [nvarchar](255) NULL,
	[InterOperatability] [nvarchar](255) NULL,
	[CreatedOn] [datetime] NOT NULL,
	[UpdatedOn] [datetime] NULL,
 CONSTRAINT [PK_DNCRule] PRIMARY KEY CLUSTERED 
(
	[DNCId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Email_List_1000]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Email_List_1000](
	[Id] [numeric](20, 0) IDENTITY(1,1) NOT NULL,
	[EmailAddress] [nvarchar](max) NOT NULL,
	[EmailPlaceholderDetails] [xml] NULL,
	[AttemptId] [int] NOT NULL,
	[MapId] [int] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[EmailResult] [int] NOT NULL,
	[ProcessedOn] [datetime] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmailCampaign]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailCampaign](
	[EmailCampaignId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[State] [bit] NOT NULL,
	[EmailConfigId] [int] NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NOT NULL,
	[MaximumBatchSize] [int] NOT NULL,
	[TimeZone] [nvarchar](255) NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NULL,
	[DealerId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[EmailCampaignId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Name] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmailCampaign_ContactList]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailCampaign_ContactList](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[EmailColumn] [nvarchar](255) NOT NULL,
	[Placeholders] [xml] NULL,
	[Attachment] [xml] NULL,
	[Subject] [nvarchar](max) NOT NULL,
	[EmailBody] [nvarchar](max) NOT NULL,
	[ContactListId] [int] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[FilterDuplicates] [bit] NOT NULL,
	[RecurrenceType] [int] NOT NULL,
	[RecurrenceInterval] [numeric](10, 0) NULL,
	[RecurrenceIntervalUnit] [int] NULL,
	[RecurrenceIntervalInHours] [numeric](10, 0) NULL,
	[RecurrenceLimit] [int] NULL,
	[RecurrenceCount] [int] NULL,
	[NextAttemptDateTime] [datetime] NULL,
	[Status] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[ContactListId] ASC,
	[CampaignId] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmailConfiguration]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailConfiguration](
	[EmailConfigID] [int] IDENTITY(10000,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[EmailHost] [nvarchar](max) NOT NULL,
	[SMTPPort] [int] NOT NULL,
	[EmailUsername] [nvarchar](max) NOT NULL,
	[EmailPassword] [nvarchar](max) NOT NULL,
	[FromAddress] [nvarchar](max) NOT NULL,
	[IsSSL] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
 CONSTRAINT [PK__EmailCon__C57B0D292C3393D0] PRIMARY KEY CLUSTERED 
(
	[EmailConfigID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_ECG] UNIQUE NONCLUSTERED 
(
	[Name] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmailContactList_Status]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailContactList_Status](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MapId] [int] NOT NULL,
	[TotalRecords] [int] NOT NULL,
	[InvalidRecords] [int] NOT NULL,
	[DuplicateRecords] [int] NOT NULL,
	[RecordsProcessed] [int] NOT NULL,
	[EndPosition] [nvarchar](255) NULL,
	[LastProcessedOn] [datetime] NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
 CONSTRAINT [PK__EmailCon__3214EC073DD3211E] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[EmailTemplates]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[EmailTemplates](
	[EmailTemplateID] [int] IDENTITY(1000000,1) NOT NULL,
	[EmailTemplateName] [nvarchar](100) NOT NULL,
	[EmailBody] [nvarchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
 CONSTRAINT [PK__EmailTem__BC0A38554D2A7347] PRIMARY KEY CLUSTERED 
(
	[EmailTemplateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__EmailTem__9DC709855F492382] UNIQUE NONCLUSTERED 
(
	[EmailTemplateName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Enable_Details]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Enable_Details](
	[Table] [sysname] NOT NULL,
	[constraint] [sysname] NOT NULL,
	[enabled] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Global_DNC]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Global_DNC](
	[DNCId] [uniqueidentifier] NOT NULL,
	[PhoneNumber] [nvarchar](50) NOT NULL,
	[Status] [int] NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[AgentMarkedOn] [datetime] NULL,
	[DNCRuleId] [int] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Global_DNC_ID] PRIMARY KEY CLUSTERED 
(
	[DNCId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Global_DNCAutomation]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Global_DNCAutomation](
	[DNCId] [uniqueidentifier] NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[FolderPath] [nvarchar](max) NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK_Global_DNCAutomation_ID] PRIMARY KEY CLUSTERED 
(
	[DNCId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GlobalDNC]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GlobalDNC](
	[DNCId] [uniqueidentifier] NOT NULL,
	[PhoneNumber] [nvarchar](255) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DNCRuleId] [int] NULL,
UNIQUE NONCLUSTERED 
(
	[PhoneNumber] ASC,
	[DNCRuleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GlobalDNCMap]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GlobalDNCMap](
	[DNCMapId] [int] IDENTITY(1,1) NOT NULL,
	[FilePath] [nvarchar](255) NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[Status] [int] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Holiday]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Holiday](
	[HolidayId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[StartDate] [date] NOT NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NOT NULL,
	[EndDate] [date] NULL,
	[Recurrence] [int] NOT NULL,
	[RecurrenceInterval] [numeric](10, 2) NULL,
	[NextIterationDate] [date] NULL,
	[Status] [int] NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NULL,
	[DealerId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[HolidayId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[Name] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Import_MultiList_1000]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Import_MultiList_1000](
	[ImportList_Id] [numeric](20, 0) IDENTITY(1,1) NOT NULL,
	[Phone01] [nvarchar](20) NULL,
	[Phone01_Formatted] [nvarchar](20) NULL,
	[Phone02] [nvarchar](20) NULL,
	[Phone02_Formatted] [nvarchar](20) NULL,
	[Phone03] [nvarchar](20) NULL,
	[Phone03_Formatted] [nvarchar](20) NULL,
	[Phone04] [nvarchar](20) NULL,
	[Phone04_Formatted] [nvarchar](20) NULL,
	[Phone05] [nvarchar](20) NULL,
	[Phone05_Formatted] [nvarchar](20) NULL,
	[Phone06] [nvarchar](20) NULL,
	[Phone06_Formatted] [nvarchar](20) NULL,
	[Phone07] [nvarchar](20) NULL,
	[Phone07_Formatted] [nvarchar](20) NULL,
	[Phone08] [nvarchar](20) NULL,
	[Phone08_Formatted] [nvarchar](20) NULL,
	[Phone09] [nvarchar](20) NULL,
	[Phone09_Formatted] [nvarchar](20) NULL,
	[Phone10] [nvarchar](20) NULL,
	[Phone10_Formatted] [nvarchar](20) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[AccountNumber] [nvarchar](50) NULL,
	[TimeZoneBias] [int] NULL,
	[DstObserved] [bit] NULL,
	[Status] [int] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[AttemptId] [int] NULL,
	[MapId] [int] NULL,
	[ExtraData] [xml] NULL,
	[DateTime] [datetime] NULL,
	[ScheduledDateTime] [datetime] NULL,
	[PhoneToCallNext] [int] NOT NULL,
	[CallResult] [int] NOT NULL,
	[AttemptsMade] [int] NOT NULL,
	[DialAttempts] [int] NOT NULL,
	[ImportDateTime] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ImportList_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ImportList_Source]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ImportList_Source](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Type] [int] NOT NULL,
	[Configuration] [xml] NOT NULL,
	[IsActive] [bit] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[TenantId] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
	[AutoGenerated] [bit] NULL,
 CONSTRAINT [PK__ImportLi__3214EC07369C13AA] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__ImportLi__719C308847C69FAC] UNIQUE NONCLUSTERED 
(
	[Name] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[License_Master_UniAgent]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[License_Master_UniAgent](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[TimeStamp] [datetime] NULL,
	[TotalLicense] [int] NULL,
	[UsedLicense] [int] NULL,
	[IsActive] [char](10) NULL,
	[Userid] [varchar](50) NULL,
 CONSTRAINT [PK_License_Master_UniAgent] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MultiContactList_ImportStatus]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MultiContactList_ImportStatus](
	[CampaignList_Id] [int] IDENTITY(1,1) NOT NULL,
	[ListId] [int] NOT NULL,
	[TotalRecordImported] [int] NOT NULL,
	[TotalDncFiltered] [int] NULL,
	[TotalDuplicateFiltered] [int] NULL,
	[TotalInvalid] [int] NULL,
	[FinishIndex] [nvarchar](1000) NULL,
	[IsImported]  AS (CONVERT([bit],case when [LastAttemptedOn] IS NOT NULL AND [TotalRecords]=((([TotalRecordImported]+[TotalDncFiltered])+[TotalInvalid])+[TotalDuplicateFiltered]) then (1) else (0) end,(0))),
	[TotalRecords] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[LastAttemptedOn] [datetime] NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DateTime] [datetime] NULL,
	[CampaignId] [int] NULL,
 CONSTRAINT [PK__ContactL__DE91FE4A284DF4544] PRIMARY KEY CLUSTERED 
(
	[CampaignList_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MultiContactListConfig]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MultiContactListConfig](
	[MultiListId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](55) NOT NULL,
	[Purpose] [int] NOT NULL,
	[SourceId] [int] NOT NULL,
	[MultiListDetails] [xml] NOT NULL,
	[HeaderMap] [xml] NOT NULL,
	[Country] [nvarchar](4) NOT NULL,
	[Timezone] [nvarchar](255) NULL,
	[DuplicateFilter] [bit] NULL,
	[DuplicateRule] [xml] NULL,
	[ExclusionList] [bit] NULL,
	[Filters] [xml] NULL,
	[ScheduleStart] [datetime] NULL,
	[Recurrence] [int] NOT NULL,
	[Recurrence_Interval] [numeric](10, 2) NULL,
	[RecurrenceUnit] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[Status] [int] NULL,
	[ExtraDetails] [xml] NOT NULL,
	[OverwriteData] [bit] NOT NULL,
	[TenantId] [int] NULL,
	[IsActive] [bit] NULL,
	[TimeZone_bias] [nvarchar](100) NULL,
	[DstObserved] [nvarchar](100) NULL,
	[DealerId] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MultipleContactListData]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MultipleContactListData](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Phone01] [nvarchar](20) NULL,
	[Phone02] [nvarchar](20) NULL,
	[Phone03] [nvarchar](20) NULL,
	[Phone04] [nvarchar](20) NULL,
	[Phone05] [nvarchar](20) NULL,
	[Phone06] [nvarchar](20) NULL,
	[Phone07] [nvarchar](20) NULL,
	[Phone08] [nvarchar](20) NULL,
	[Phone09] [nvarchar](20) NULL,
	[Phone10] [nvarchar](20) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[AccountNumber] [nvarchar](50) NULL,
	[Status] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[MapId] [int] NULL,
	[DateTime] [datetime] NULL,
	[TimeZoneBias] [nvarchar](100) NULL,
	[DstObserved] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[NationalDNC]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[NationalDNC](
	[DNCId] [int] IDENTITY(1000,1) NOT NULL,
	[PhoneNumber] [nvarchar](255) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DealerId] [int] NULL,
	[DNCRuleId] [int] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Outbound_Call_Detail_1000]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Outbound_Call_Detail_1000](
	[Id] [numeric](25, 0) IDENTITY(1,1) NOT NULL,
	[RecoveryKey] [numeric](18, 0) NULL,
	[DateTime] [datetime] NULL,
	[DateTimeUtc] [datetime] NULL,
	[ImportRuleDateTime] [datetime] NULL,
	[ImportRuleDateTimeUtc] [datetime] NULL,
	[CampaignID] [int] NULL,
	[CallResult] [int] NULL,
	[CustomerTimeZone] [int] NULL,
	[Phone] [nvarchar](20) NULL,
	[AccountNumber] [nvarchar](50) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[CallbackDateTime] [datetime] NULL,
	[WrapupData] [nvarchar](max) NULL,
	[CallGUID] [nvarchar](200) NULL,
	[AgentSkillGroupID] [int] NULL,
	[AgentName] [nvarchar](max) NULL,
	[AgentLoginName] [nvarchar](max) NULL,
	[AgentId] [nvarchar](max) NULL,
	[SkillGroupSkillTargetID] [int] NULL,
	[Status] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PreviewCampaign]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreviewCampaign](
	[PreviewCampaignId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[State] [bit] NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NOT NULL,
	[TargetCountry] [nvarchar](4) NULL,
	[TenantId] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NULL,
	[TimeZone] [nvarchar](255) NULL,
	[CreatedOn] [datetime] NULL,
	[NoOfSkill] [int] NOT NULL,
	[Prefix] [nvarchar](15) NULL,
 CONSTRAINT [PK__PreviewCampaign__B69DFF880F4D3C5F] PRIMARY KEY CLUSTERED 
(
	[PreviewCampaignId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PreviewCampaignContact_List]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreviewCampaignContact_List](
	[CampaignList_Id] [int] IDENTITY(1,1) NOT NULL,
	[CampaignId] [int] NOT NULL,
	[ListId] [int] NOT NULL,
	[HeaderMap] [xml] NULL,
	[TargetCountry] [nvarchar](4) NOT NULL,
	[TimeZone] [nvarchar](255) NULL,
	[FilterDuplicate] [bit] NULL,
	[FilterDNC] [bit] NULL,
	[KeepHeaders] [bit] NULL,
	[DuplicateRules] [xml] NULL,
	[TenantId] [int] NOT NULL,
	[Status] [int] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[DealerId] [int] NOT NULL,
 CONSTRAINT [PK__Campaign__DE91FE4A4A18FC75] PRIMARY KEY CLUSTERED 
(
	[CampaignList_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_PreviewCampaignContact_List] UNIQUE NONCLUSTERED 
(
	[CampaignId] ASC,
	[ListId] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PreviewCampaignImportList]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreviewCampaignImportList](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PhoneNumber] [nvarchar](20) NULL,
	[PhoneNumber_Formatted] [nvarchar](20) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[EmailId] [nvarchar](50) NULL,
	[DOB] [nvarchar](50) NULL,
	[State] [nvarchar](50) NULL,
	[Status] [int] NOT NULL,
	[ExtraDetails] [xml] NULL,
	[CampaignId] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
	[MapId] [int] NULL,
	[DateTime] [datetime] NULL,
	[AttemptId] [int] NULL,
	[AgentId] [int] NULL,
	[AgentLoginName] [nvarchar](255) NULL,
	[CallResult] [int] NOT NULL,
	[ImportedDateTime] [datetime] NULL,
	[DialAtempts] [int] NULL,
	[CallDispostion] [int] NULL,
	[RingTime] [int] NULL,
	[DelayTime] [int] NULL,
	[HoldTime] [int] NULL,
	[TalkTime] [int] NULL,
	[WorkTime] [int] NULL,
	[LocalQTime] [int] NULL,
	[ImportedTime] [datetime] NULL,
	[WrapupData] [nvarchar](40) NULL,
	[TCD_RecoveryKey] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PreviewImportStatus]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreviewImportStatus](
	[CampaignList_Id] [int] IDENTITY(1,1) NOT NULL,
	[ListId] [int] NOT NULL,
	[TotalRecordImported] [int] NOT NULL,
	[TotalDncFiltered] [int] NULL,
	[TotalDuplicateFiltered] [int] NULL,
	[TotalInvalid] [int] NULL,
	[FinishIndex] [nvarchar](1000) NULL,
	[IsImported]  AS (CONVERT([bit],case when [LastAttemptedOn] IS NOT NULL AND [TotalRecords]=((([TotalRecordImported]+[TotalDncFiltered])+[TotalInvalid])+[TotalDuplicateFiltered]) then (1) else (0) end,(0))),
	[TotalRecords] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[LastAttemptedOn] [datetime] NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DateTime] [datetime] NULL,
 CONSTRAINT [PK__ContactL__DE91FE4A284DF476] PRIMARY KEY CLUSTERED 
(
	[CampaignList_Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[PreviewWarpReasonCode]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PreviewWarpReasonCode](
	[WrapupCodeId] [int] IDENTITY(1000,1) NOT NULL,
	[WrapUpCodeName] [nvarchar](50) NOT NULL,
	[TenantId] [int] NOT NULL,
	[Description] [nvarchar](255) NULL,
	[DealerId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[UpdateOn] [datetime] NULL,
	[IsActive] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[WrapupCodeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[DealerId] ASC,
	[WrapUpCodeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RechurnPolicy]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RechurnPolicy](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[Description ] [nvarchar](max) NULL,
	[Schedule] [int] NULL,
	[IsManual] [bit] NULL,
	[CallResultsDetailsXml] [xml] NOT NULL,
	[Status] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DealerId] [int] NOT NULL,
	[AgentDispositionsDetailsXml] [xml] NULL,
	[IsActive] [bit] NOT NULL,
	[DialAttempt] [int] NULL,
	[DialAttemptCondition] [int] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RechurnPolicy1]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RechurnPolicy1](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[RechurnRecurrenceType] [int] NOT NULL,
	[StartDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NOT NULL,
	[Frequency] [int] NOT NULL,
	[Policy] [xml] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DealerId] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[IsActive] [int] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RechurnPolicyMap]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RechurnPolicyMap](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PolicyId] [int] NOT NULL,
	[Campaign] [int] NOT NULL,
	[ContactMap] [int] NULL,
	[Status] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RecurrenceSchedule]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RecurrenceSchedule](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](max) NOT NULL,
	[Description ] [nvarchar](max) NOT NULL,
	[ScheduleType] [int] NOT NULL,
	[Frequency] [int] NOT NULL,
	[RecurrenceInterval] [numeric](10, 2) NULL,
	[RecurrenceUnit] [int] NULL,
	[StartDateTime] [datetime] NULL,
	[EndDateTime] [datetime] NULL,
	[Status] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[NextIterationDate] [date] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Role_Master]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Role_Master](
	[RoleId] [int] IDENTITY(1,1) NOT NULL,
	[TenantId] [int] NOT NULL,
	[FeatureMap] [xml] NULL,
	[Name] [nvarchar](100) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CreadtedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[RoleId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Schedule_Mail]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Schedule_Mail](
	[CampaignId] [int] NOT NULL,
	[FromAddress] [nvarchar](255) NULL,
	[ToAddress] [nvarchar](255) NULL,
	[SubjectLine] [nvarchar](255) NULL,
	[ScheduledDays] [nvarchar](max) NULL,
	[ScheduledTime] [time](7) NULL,
PRIMARY KEY CLUSTERED 
(
	[CampaignId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SkillGroupMap]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SkillGroupMap](
	[SkillMapId] [int] IDENTITY(1,1) NOT NULL,
	[PreviewCampaignId] [nvarchar](255) NULL,
	[SkillTargetID] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
 CONSTRAINT [PK__PreviewCampaign__B69DFF880F4D3C5FC] PRIMARY KEY CLUSTERED 
(
	[SkillMapId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SMS_List_1000]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMS_List_1000](
	[Id] [numeric](20, 0) IDENTITY(1,1) NOT NULL,
	[PhoneNumber] [nvarchar](20) NOT NULL,
	[PhoneNumberFormatted] [nvarchar](20) NULL,
	[PlaceholderDetails] [xml] NULL,
	[AttemptId] [int] NOT NULL,
	[MapId] [int] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[SMSResult] [int] NOT NULL,
	[ProcessedOn] [datetime] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SMSCampaign]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMSCampaign](
	[SMSCampaignId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Description] [nvarchar](255) NULL,
	[State] [bit] NOT NULL,
	[SMSConfigId] [int] NOT NULL,
	[StartDate] [date] NULL,
	[EndDate] [date] NULL,
	[StartTime] [time](7) NOT NULL,
	[EndTime] [time](7) NOT NULL,
	[MaximumBatchSize] [int] NOT NULL,
	[TargetCountry] [nvarchar](4) NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[IsActive] [bit] NULL,
	[TimeZone] [nvarchar](255) NULL,
	[DealerId] [int] NOT NULL,
 CONSTRAINT [PK__SMSCampa__B69DFF880F4D3C5F] PRIMARY KEY CLUSTERED 
(
	[SMSCampaignId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__SMSCampa__719C30881229A90A] UNIQUE NONCLUSTERED 
(
	[Name] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SMSCampaign_ContactList]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMSCampaign_ContactList](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[PhoneColumn] [nvarchar](255) NOT NULL,
	[Placeholders] [xml] NULL,
	[TargetCountry] [nvarchar](4) NOT NULL,
	[Message] [nvarchar](max) NOT NULL,
	[ContactListId] [int] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[FilterDuplicates] [bit] NOT NULL,
	[RecurrenceType] [int] NOT NULL,
	[RecurrenceInterval] [numeric](10, 0) NULL,
	[RecurrenceIntervalUnit] [int] NULL,
	[RecurrenceIntervalInHours] [numeric](10, 0) NULL,
	[RecurrenceLimit] [int] NULL,
	[RecurrenceCount] [int] NULL,
	[NextAttemptDateTime] [datetime] NULL,
	[Status] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
 CONSTRAINT [PK__SMSCampa__3214EC075026DB83] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ__SMSCampa__7E46E2145303482E] UNIQUE NONCLUSTERED 
(
	[ContactListId] ASC,
	[CampaignId] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SMSConfiguration]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMSConfiguration](
	[SMSConfigId] [int] IDENTITY(1000000,1) NOT NULL,
	[SMSConfigName] [nvarchar](100) NOT NULL,
	[Configuration] [xml] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[Type] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[DealerId] [int] NOT NULL,
 CONSTRAINT [PK_SMSConfiguration] PRIMARY KEY CLUSTERED 
(
	[SMSConfigId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UniqueSMSConfig] UNIQUE NONCLUSTERED 
(
	[SMSConfigName] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SMSContactList_Status]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMSContactList_Status](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[MapId] [int] NOT NULL,
	[TotalRecords] [int] NOT NULL,
	[InvalidRecords] [int] NOT NULL,
	[DuplicateRecords] [int] NOT NULL,
	[RecordsProcessed] [int] NOT NULL,
	[EndPosition] [nvarchar](255) NULL,
	[LastProcessedOn] [datetime] NULL,
	[TenantId] [int] NOT NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SMSTemplates]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SMSTemplates](
	[SMSTemplateID] [int] IDENTITY(1000000,1) NOT NULL,
	[SMSTemplateName] [nvarchar](100) NOT NULL,
	[SMSMessage] [nvarchar](max) NOT NULL,
	[IsActive] [bit] NOT NULL,
	[TenantId] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
 CONSTRAINT [PK_SMSTemplates] PRIMARY KEY CLUSTERED 
(
	[SMSTemplateID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UniqueSmsTemplate] UNIQUE NONCLUSTERED 
(
	[SMSTemplateName] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Tenants]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tenants](
	[Id] [int] IDENTITY(1000,1) NOT NULL,
	[Name] [nvarchar](50) NOT NULL,
	[Configuration] [xml] NOT NULL,
	[IsActive] [bit] NULL,
 CONSTRAINT [PK__Tenants__3214EC073A6CA48E] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UniqueTenant] UNIQUE NONCLUSTERED 
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
/****** Object:  Table [dbo].[test_replication]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[test_replication](
	[id] [int] NULL,
	[dates] [datetime] NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UCCE_Skill_Group]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UCCE_Skill_Group](
	[SkillTargetID] [int] NOT NULL,
	[PrecisionQueueID] [int] NULL,
	[ScheduleID] [int] NULL,
	[PeripheralID] [int] NOT NULL,
	[EnterpriseName] [nvarchar](255) NOT NULL,
	[PeripheralNumber] [int] NOT NULL,
	[PeripheralName] [nvarchar](255) NOT NULL,
	[AvailableHoldoffDelay] [int] NOT NULL,
	[Priority] [int] NOT NULL,
	[BaseSkillTargetID] [int] NULL,
	[Extension] [nvarchar](255) NULL,
	[SubGroupMaskType] [int] NOT NULL,
	[SubSkillGroupMask] [nvarchar](64) NULL,
	[ConfigParam] [nvarchar](255) NULL,
	[Description] [nvarchar](255) NULL,
	[Deleted] [nvarchar](255) NOT NULL,
	[MRDomainID] [int] NOT NULL,
	[IPTA] [nvarchar](255) NOT NULL,
	[DefaultEntry] [nvarchar](255) NOT NULL,
	[UserDeletable] [nvarchar](255) NOT NULL,
	[ServiceLevelThreshold] [int] NOT NULL,
	[ServiceLevelType] [int] NOT NULL,
	[BucketIntervalID] [int] NULL,
	[ChangeStamp] [nvarchar](255) NOT NULL,
	[DepartmentID] [int] NULL,
	[DateTimeStamp] [datetime] NULL,
 CONSTRAINT [XPKSkill_Group] PRIMARY KEY CLUSTERED 
(
	[SkillTargetID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY],
 CONSTRAINT [XAK1Skill_Group] UNIQUE NONCLUSTERED 
(
	[EnterpriseName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY],
 CONSTRAINT [XAK2Skill_Group] UNIQUE NONCLUSTERED 
(
	[PeripheralID] ASC,
	[PeripheralNumber] ASC,
	[Priority] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UCCEAgent]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UCCEAgent](
	[SkillTargetID] [int] NOT NULL,
	[PersonID] [int] NOT NULL,
	[AgentDeskSettingsID] [int] NULL,
	[ScheduleID] [int] NULL,
	[PeripheralID] [int] NOT NULL,
	[EnterpriseName] [nvarchar](255) NOT NULL,
	[PeripheralNumber] [nvarchar](255) NOT NULL,
	[ConfigParam] [nvarchar](255) NULL,
	[Description] [nvarchar](255) NULL,
	[Deleted] [nvarchar](255) NOT NULL,
	[PeripheralName] [nvarchar](255) NULL,
	[TemporaryAgent] [nvarchar](255) NOT NULL,
	[AgentStateTrace] [nvarchar](255) NOT NULL,
	[SupervisorAgent] [nvarchar](255) NOT NULL,
	[ChangeStamp] [nvarchar](255) NOT NULL,
	[UserDeletable] [nvarchar](255) NOT NULL,
	[DefaultSkillGroup] [int] NULL,
	[DepartmentID] [int] NULL,
	[DateTimeStamp] [datetime] NULL,
	[LoginName] [nvarchar](255) NOT NULL
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UniCampaignSession]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UniCampaignSession](
	[SessionId] [int] IDENTITY(1,1) NOT NULL,
	[UserId] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[StartDateTime] [datetime] NOT NULL,
	[EndDateTime] [datetime] NULL,
	[ExtraDetails] [nvarchar](600) NULL,
PRIMARY KEY CLUSTERED 
(
	[SessionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[User_Master]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[User_Master](
	[UserId] [int] IDENTITY(1,1) NOT NULL,
	[UserName] [nvarchar](100) NOT NULL,
	[Password] [nvarchar](50) NOT NULL,
	[TenantId] [int] NOT NULL,
	[RoleId] [int] NOT NULL,
	[DealerId] [int] NOT NULL,
	[CreadtedOn] [datetime] NOT NULL,
	[IsActive] [bit] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[PasswordUpdatedOn] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
UNIQUE NONCLUSTERED 
(
	[UserName] ASC,
	[DealerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[UserMaster]    Script Date: 18-09-2024 7.30.44 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[UserMaster](
	[UserId] [int] IDENTITY(1000,1) NOT NULL,
	[Username] [nvarchar](50) NOT NULL,
	[Password] [nvarchar](255) NOT NULL,
	[Role] [int] NOT NULL,
	[TenantId] [int] NOT NULL,
	[IsActive] [bit] NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL,
	[PasswordUpdatedOn] [datetime] NULL,
 CONSTRAINT [PK__UserMast__1788CC4C3F3159AB] PRIMARY KEY CLUSTERED 
(
	[UserId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UniqueUser] UNIQUE NONCLUSTERED 
(
	[Username] ASC,
	[TenantId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[AgentScripts] ADD  CONSTRAINT [DF__AgentScript__IsAct__4F12BBB9]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Audit_Trail] ADD  DEFAULT ((0)) FOR [UserId]
GO
ALTER TABLE [dbo].[Audit_Trail] ADD  DEFAULT ((0)) FOR [TenantId]
GO
ALTER TABLE [dbo].[BulkCallback] ADD  DEFAULT ((0)) FOR [OverwriteData]
GO
ALTER TABLE [dbo].[BulkCallback] ADD  DEFAULT (',') FOR [Delimiter]
GO
ALTER TABLE [dbo].[BulkCallback] ADD  DEFAULT ((0)) FOR [IsProcessed]
GO
ALTER TABLE [dbo].[BulkCallback] ADD  DEFAULT ((0)) FOR [TenantId]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF_CampaignContact_List_TargetCountry]  DEFAULT (N'IN') FOR [TargetCountry]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__Recur__4CF5691D]  DEFAULT ((1)) FOR [Recurrence]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__Recur__117F9D94]  DEFAULT ((2)) FOR [RecurrenceUnit]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__Filte__4DE98D56]  DEFAULT ((1)) FOR [FilterDuplicate]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__Filte__4EDDB18F]  DEFAULT ((1)) FOR [FilterDNC]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__KeepH__4FD1D5C8]  DEFAULT ((0)) FOR [KeepHeaders]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__Overw__108B795B]  DEFAULT ((0)) FOR [OverwriteData]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__Tenan__1273C1CD]  DEFAULT ((0)) FOR [TenantId]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__Statu__50C5FA01]  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[CampaignContact_List] ADD  CONSTRAINT [DF__CampaignC__IsAct__51BA1E3A]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CampaignExtraDetails] ADD  CONSTRAINT [DF__CampaignE__Creat__23F3538A]  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[CampaignExtraDetails] ADD  CONSTRAINT [DF_Campaign_ExtraDetails_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CampaignHoliday] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[CampaignHoliday] ADD  DEFAULT (getutcdate()) FOR [DateTime]
GO
ALTER TABLE [dbo].[CampaignMultipleContact_List] ADD  CONSTRAINT [DF_CListForMultipleCampaign_TargetCountry]  DEFAULT (N'IN') FOR [TargetCountry]
GO
ALTER TABLE [dbo].[CampaignMultipleContact_List] ADD  CONSTRAINT [DF__ListForMultipleCampaign__Recur__4CF5691D]  DEFAULT ((1)) FOR [Recurrence]
GO
ALTER TABLE [dbo].[CampaignMultipleContact_List] ADD  CONSTRAINT [DF__ListForMultipleCampaign__Recur__117F9D94]  DEFAULT ((2)) FOR [RecurrenceUnit]
GO
ALTER TABLE [dbo].[CampaignMultipleContact_List] ADD  CONSTRAINT [DF__ListForMultipleCampaign__Filte__4DE98D56]  DEFAULT ((1)) FOR [FilterDuplicate]
GO
ALTER TABLE [dbo].[CampaignMultipleContact_List] ADD  CONSTRAINT [DF__ListForMultipleCampaign__Filte__4EDDB18F]  DEFAULT ((1)) FOR [FilterDNC]
GO
ALTER TABLE [dbo].[CBMConfig] ADD  DEFAULT ((1)) FOR [MaximumAttempts]
GO
ALTER TABLE [dbo].[CBMConfig] ADD  DEFAULT ((0)) FOR [Level]
GO
ALTER TABLE [dbo].[ClicktoCallData] ADD  DEFAULT (newid()) FOR [ImportId]
GO
ALTER TABLE [dbo].[ClicktoCallData] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Contact_List] ADD  CONSTRAINT [DF_Contact_List_Purpose]  DEFAULT ((0)) FOR [Purpose]
GO
ALTER TABLE [dbo].[Contact_List] ADD  CONSTRAINT [DF__Contact_L__IsAct__473C8FC7]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Contact_List] ADD  CONSTRAINT [D_Contact_List_AutoGenerated]  DEFAULT ((0)) FOR [AutoGenerated]
GO
ALTER TABLE [dbo].[ContactList_ImportStatus] ADD  CONSTRAINT [DF__ContactLi__Total__5DB5E0CB]  DEFAULT ((0)) FOR [TotalRecords]
GO
ALTER TABLE [dbo].[ContactList_ImportStatus] ADD  CONSTRAINT [DF_ContactList_ImportStatus_CreatedOn]  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[ContactList_ImportStatus] ADD  CONSTRAINT [DF__ContactLi__LastI__51EA9624]  DEFAULT ((0)) FOR [LastImportFailedRecords]
GO
ALTER TABLE [dbo].[ContactList_ImportStatus] ADD  CONSTRAINT [DF__ContactLi__Statu__086B34A6]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[ContactListSequence] ADD  DEFAULT (',') FOR [Delimiter]
GO
ALTER TABLE [dbo].[ContactListSequence] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[ContactListSequence] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ContactListSequence] ADD  DEFAULT ((1)) FOR [IntervalUnit]
GO
ALTER TABLE [dbo].[ContactListSequence] ADD  DEFAULT ((1)) FOR [Headers]
GO
ALTER TABLE [dbo].[ContactListSequenceIteration] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[ContactListSequenceIteration] ADD  DEFAULT ((0)) FOR [IsFileRead]
GO
ALTER TABLE [dbo].[ContactMapAppendConfig] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT (N'IN') FOR [TargetCountry]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT ((1)) FOR [Recurrence]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT ((2)) FOR [RecurrenceUnit]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT ((1)) FOR [FilterDuplicate]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT ((1)) FOR [FilterDNC]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT ((0)) FOR [KeepHeaders]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT ((0)) FOR [OverwriteData]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ContactMapGroup] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[ContactMapGroupIteration] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[ContactMapGroupIteration] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[CustomDNC] ADD  DEFAULT ((-20)) FOR [CampaignId]
GO
ALTER TABLE [dbo].[CustomDNC] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[CustomDNC] ADD  DEFAULT ((0)) FOR [TenantId]
GO
ALTER TABLE [dbo].[CustomDNCMaruti] ADD  CONSTRAINT [MSmerge_df_rowguid_81072C26B68E4411A35EB8D2F8BD9812]  DEFAULT (newsequentialid()) FOR [rowguid]
GO
ALTER TABLE [dbo].[Dealer] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Dealer] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Dealer] ADD  CONSTRAINT [D_Dealer_Status]  DEFAULT ((2)) FOR [Status]
GO
ALTER TABLE [dbo].[DealerExtraDetails] ADD  DEFAULT (getutcdate()) FOR [AssignedOn]
GO
ALTER TABLE [dbo].[DealerExtraDetails] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[DNC_Test] ADD  DEFAULT (newid()) FOR [Id]
GO
ALTER TABLE [dbo].[Email_List_1000] ADD  DEFAULT ((0)) FOR [EmailResult]
GO
ALTER TABLE [dbo].[Email_List_1000] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[EmailCampaign] ADD  DEFAULT ((0)) FOR [State]
GO
ALTER TABLE [dbo].[EmailCampaign] ADD  DEFAULT ((100)) FOR [MaximumBatchSize]
GO
ALTER TABLE [dbo].[EmailCampaign] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[EmailCampaign] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList] ADD  DEFAULT ((0)) FOR [FilterDuplicates]
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList] ADD  DEFAULT ((0)) FOR [RecurrenceCount]
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[EmailConfiguration] ADD  CONSTRAINT [DF__EmailConf__IsSSL__2E1BDC42]  DEFAULT ((0)) FOR [IsSSL]
GO
ALTER TABLE [dbo].[EmailConfiguration] ADD  CONSTRAINT [DF__EmailConf__IsAct__2F10007B]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[EmailContactList_Status] ADD  CONSTRAINT [DF__EmailCont__Total__29971E47]  DEFAULT ((0)) FOR [TotalRecords]
GO
ALTER TABLE [dbo].[EmailContactList_Status] ADD  CONSTRAINT [DF__EmailCont__Inval__2A8B4280]  DEFAULT ((0)) FOR [InvalidRecords]
GO
ALTER TABLE [dbo].[EmailContactList_Status] ADD  CONSTRAINT [DF__EmailCont__Dupli__2B7F66B9]  DEFAULT ((0)) FOR [DuplicateRecords]
GO
ALTER TABLE [dbo].[EmailContactList_Status] ADD  CONSTRAINT [DF__EmailCont__Recor__2C738AF2]  DEFAULT ((0)) FOR [RecordsProcessed]
GO
ALTER TABLE [dbo].[EmailContactList_Status] ADD  CONSTRAINT [DF__EmailCont__Creat__2D67AF2B]  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[EmailTemplates] ADD  CONSTRAINT [DF__EmailTemp__IsAct__4F12BBB9]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Global_DNC] ADD  DEFAULT (newsequentialid()) FOR [DNCId]
GO
ALTER TABLE [dbo].[Global_DNC] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Global_DNC] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Global_DNC] ADD  DEFAULT ((1000)) FOR [DNCRuleId]
GO
ALTER TABLE [dbo].[Global_DNC] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Global_DNCAutomation] ADD  DEFAULT (newsequentialid()) FOR [DNCId]
GO
ALTER TABLE [dbo].[Global_DNCAutomation] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Global_DNCAutomation] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[GlobalDNC] ADD  DEFAULT (newid()) FOR [DNCId]
GO
ALTER TABLE [dbo].[GlobalDNC] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[GlobalDNC] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Holiday] ADD  DEFAULT ((0)) FOR [Recurrence]
GO
ALTER TABLE [dbo].[Holiday] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[Holiday] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Holiday] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Import_MultiList_1000] ADD  DEFAULT (getutcdate()) FOR [DateTime]
GO
ALTER TABLE [dbo].[Import_MultiList_1000] ADD  DEFAULT (getutcdate()) FOR [ScheduledDateTime]
GO
ALTER TABLE [dbo].[Import_MultiList_1000] ADD  DEFAULT ((1)) FOR [PhoneToCallNext]
GO
ALTER TABLE [dbo].[Import_MultiList_1000] ADD  DEFAULT ((0)) FOR [CallResult]
GO
ALTER TABLE [dbo].[Import_MultiList_1000] ADD  DEFAULT ((0)) FOR [AttemptsMade]
GO
ALTER TABLE [dbo].[Import_MultiList_1000] ADD  DEFAULT ((0)) FOR [DialAttempts]
GO
ALTER TABLE [dbo].[Import_MultiList_1000] ADD  DEFAULT (NULL) FOR [ImportDateTime]
GO
ALTER TABLE [dbo].[ImportList_Source] ADD  CONSTRAINT [DF__ImportLis__IsAct__673F4B05]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ImportList_Source] ADD  CONSTRAINT [DF__ImportLis__Tenan__68336F3E]  DEFAULT ((0)) FOR [TenantId]
GO
ALTER TABLE [dbo].[ImportList_Source] ADD  CONSTRAINT [D_ImportList_Source_AutoGenerated]  DEFAULT ((0)) FOR [AutoGenerated]
GO
ALTER TABLE [dbo].[MultiContactList_ImportStatus] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[MultiContactList_ImportStatus] ADD  DEFAULT (getutcdate()) FOR [DateTime]
GO
ALTER TABLE [dbo].[MultiContactListConfig] ADD  DEFAULT ((0)) FOR [DuplicateFilter]
GO
ALTER TABLE [dbo].[MultiContactListConfig] ADD  DEFAULT ((0)) FOR [ExclusionList]
GO
ALTER TABLE [dbo].[MultiContactListConfig] ADD  DEFAULT ((0)) FOR [OverwriteData]
GO
ALTER TABLE [dbo].[MultiContactListConfig] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[MultipleContactListData] ADD  DEFAULT (getutcdate()) FOR [DateTime]
GO
ALTER TABLE [dbo].[NationalDNC] ADD  DEFAULT ((1)) FOR [TenantId]
GO
ALTER TABLE [dbo].[NationalDNC] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Outbound_Call_Detail_1000] ADD  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[PreviewCampaign] ADD  CONSTRAINT [DF__PreviewCampai__IsAct__18D6A699]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[PreviewCampaign] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[PreviewCampaignContact_List] ADD  DEFAULT (N'IN') FOR [TargetCountry]
GO
ALTER TABLE [dbo].[PreviewCampaignContact_List] ADD  DEFAULT ((1)) FOR [FilterDuplicate]
GO
ALTER TABLE [dbo].[PreviewCampaignContact_List] ADD  DEFAULT ((1)) FOR [FilterDNC]
GO
ALTER TABLE [dbo].[PreviewCampaignContact_List] ADD  DEFAULT ((0)) FOR [KeepHeaders]
GO
ALTER TABLE [dbo].[PreviewCampaignContact_List] ADD  DEFAULT ((0)) FOR [TenantId]
GO
ALTER TABLE [dbo].[PreviewCampaignContact_List] ADD  DEFAULT ((0)) FOR [Status]
GO
ALTER TABLE [dbo].[PreviewCampaignContact_List] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[PreviewCampaignImportList] ADD  DEFAULT (getutcdate()) FOR [DateTime]
GO
ALTER TABLE [dbo].[PreviewCampaignImportList] ADD  DEFAULT ((0)) FOR [CallResult]
GO
ALTER TABLE [dbo].[PreviewImportStatus] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[PreviewImportStatus] ADD  DEFAULT (getutcdate()) FOR [DateTime]
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RechurnPolicy] ADD  DEFAULT ((1)) FOR [IsManual]
GO
ALTER TABLE [dbo].[RechurnPolicy] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[RechurnPolicy] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RechurnPolicyMap] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[RechurnPolicyMap] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RecurrenceSchedule] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[Role_Master] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Role_Master] ADD  DEFAULT (getutcdate()) FOR [CreadtedOn]
GO
ALTER TABLE [dbo].[SMS_List_1000] ADD  DEFAULT ((0)) FOR [SMSResult]
GO
ALTER TABLE [dbo].[SMS_List_1000] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[SMSCampaign] ADD  CONSTRAINT [DF__SMSCampai__State__1411F17C]  DEFAULT ((0)) FOR [State]
GO
ALTER TABLE [dbo].[SMSCampaign] ADD  CONSTRAINT [DF__SMSCampai__Maxim__15FA39EE]  DEFAULT ((100)) FOR [MaximumBatchSize]
GO
ALTER TABLE [dbo].[SMSCampaign] ADD  CONSTRAINT [DF__SMSCampai__Creat__17E28260]  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[SMSCampaign] ADD  CONSTRAINT [DF__SMSCampai__IsAct__18D6A699]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList] ADD  CONSTRAINT [DF_SMSCampaign_ContactList_FilterDuplicates]  DEFAULT ((0)) FOR [FilterDuplicates]
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList] ADD  CONSTRAINT [DF__SMSCampai__Recur__57C7FD4B]  DEFAULT ((0)) FOR [RecurrenceCount]
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList] ADD  CONSTRAINT [DF__SMSCampai__Statu__58BC2184]  DEFAULT ((1)) FOR [Status]
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList] ADD  CONSTRAINT [DF__SMSCampai__Creat__59B045BD]  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[SMSConfiguration] ADD  CONSTRAINT [DF__SMSConfig__IsAct__247D636F]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[SMSContactList_Status] ADD  DEFAULT ((0)) FOR [TotalRecords]
GO
ALTER TABLE [dbo].[SMSContactList_Status] ADD  DEFAULT ((0)) FOR [InvalidRecords]
GO
ALTER TABLE [dbo].[SMSContactList_Status] ADD  DEFAULT ((0)) FOR [DuplicateRecords]
GO
ALTER TABLE [dbo].[SMSContactList_Status] ADD  DEFAULT ((0)) FOR [RecordsProcessed]
GO
ALTER TABLE [dbo].[SMSContactList_Status] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[SMSTemplates] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[Tenants] ADD  CONSTRAINT [DF__Tenants__IsActiv__3C54ED00]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UniCampaignSession] ADD  DEFAULT (getutcdate()) FOR [StartDateTime]
GO
ALTER TABLE [dbo].[UniCampaignSession] ADD  DEFAULT (NULL) FOR [EndDateTime]
GO
ALTER TABLE [dbo].[User_Master] ADD  DEFAULT (getutcdate()) FOR [CreadtedOn]
GO
ALTER TABLE [dbo].[User_Master] ADD  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UserMaster] ADD  CONSTRAINT [DF__UserMaste__IsAct__4119A21D]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[UserMaster] ADD  DEFAULT (getutcdate()) FOR [CreatedOn]
GO
ALTER TABLE [dbo].[UserMaster] ADD  DEFAULT (getutcdate()) FOR [PasswordUpdatedOn]
GO
ALTER TABLE [dbo].[AgentScripts]  WITH CHECK ADD  CONSTRAINT [FK__AgentScript__Tenan__5006DFF2] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[AgentScripts] CHECK CONSTRAINT [FK__AgentScript__Tenan__5006DFF2]
GO
ALTER TABLE [dbo].[CampaignExtraDetails]  WITH CHECK ADD  CONSTRAINT [FK__CampaignE__Tenan__22FF2F51] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignExtraDetails] CHECK CONSTRAINT [FK__CampaignE__Tenan__22FF2F51]
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([HolidayId])
REFERENCES [dbo].[Holiday] ([HolidayId])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CampaignHoliday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD  CONSTRAINT [FK__CBMConfig__Tenan__2A164134] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig] CHECK CONSTRAINT [FK__CBMConfig__Tenan__2A164134]
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[CBMConfig]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Contact_List]  WITH CHECK ADD  CONSTRAINT [FK__Contact_L__Sourc__45544755] FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[Contact_List] CHECK CONSTRAINT [FK__Contact_L__Sourc__45544755]
GO
ALTER TABLE [dbo].[ContactList_ImportStatus]  WITH CHECK ADD  CONSTRAINT [FK__ContactLi__ListI__567ED357] FOREIGN KEY([ListId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactList_ImportStatus] CHECK CONSTRAINT [FK__ContactLi__ListI__567ED357]
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD  CONSTRAINT [FK__ContactLi__Sourc__2DE6D218] FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence] CHECK CONSTRAINT [FK__ContactLi__Sourc__2DE6D218]
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([SourceId])
REFERENCES [dbo].[ImportList_Source] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD  CONSTRAINT [FK__ContactLi__Tenan__2EDAF651] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence] CHECK CONSTRAINT [FK__ContactLi__Tenan__2EDAF651]
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequence]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD  CONSTRAINT [FK__ContactLi__Seque__31B762FC] FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration] CHECK CONSTRAINT [FK__ContactLi__Seque__31B762FC]
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactListSequenceIteration]  WITH CHECK ADD FOREIGN KEY([SequenceId])
REFERENCES [dbo].[ContactListSequence] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroup]  WITH CHECK ADD FOREIGN KEY([ParentId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([GroupId])
REFERENCES [dbo].[ContactMapGroup] ([Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[ContactMapGroupIteration]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[CampaignContact_List] ([CampaignList_Id])
GO
ALTER TABLE [dbo].[DataDump_LastRecoveryKey]  WITH CHECK ADD  CONSTRAINT [FK_DataDump_LastRecoveryKey_Tenants] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[DataDump_LastRecoveryKey] CHECK CONSTRAINT [FK_DataDump_LastRecoveryKey_Tenants]
GO
ALTER TABLE [dbo].[DataDump_LastRecoveryKey_TCD]  WITH CHECK ADD  CONSTRAINT [FK_DataDump_LastRecoveryKey_Tenants1] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[DataDump_LastRecoveryKey_TCD] CHECK CONSTRAINT [FK_DataDump_LastRecoveryKey_Tenants1]
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[DealerExtraDetails]  WITH NOCHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[EmailContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[Email_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[EmailCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([EmailConfigId])
REFERENCES [dbo].[EmailConfiguration] ([EmailConfigID])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[EmailCampaign] ([EmailCampaignId])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD  CONSTRAINT [FK__EmailCamp__Conta__25518C17] FOREIGN KEY([ContactListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList] CHECK CONSTRAINT [FK__EmailCamp__Conta__25518C17]
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailCampaign_ContactList]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailConfiguration]  WITH CHECK ADD  CONSTRAINT [FK__EmailConf__Tenan__534D60F1] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailConfiguration] CHECK CONSTRAINT [FK__EmailConf__Tenan__534D60F1]
GO
ALTER TABLE [dbo].[EmailTemplates]  WITH CHECK ADD  CONSTRAINT [FK__EmailTemp__Tenan__5006DFF2] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[EmailTemplates] CHECK CONSTRAINT [FK__EmailTemp__Tenan__5006DFF2]
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Holiday]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([DealerId])
REFERENCES [dbo].[Dealer] ([DealerId])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[PreviewWarpReasonCode]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[Role_Master]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([AttemptId])
REFERENCES [dbo].[SMSContactList_Status] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMS_List_1000]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSCampaign]  WITH CHECK ADD  CONSTRAINT [FK__SMSCampai__SMSCo__150615B5] FOREIGN KEY([SMSConfigId])
REFERENCES [dbo].[SMSConfiguration] ([SMSConfigId])
GO
ALTER TABLE [dbo].[SMSCampaign] CHECK CONSTRAINT [FK__SMSCampai__SMSCo__150615B5]
GO
ALTER TABLE [dbo].[SMSCampaign]  WITH CHECK ADD  CONSTRAINT [FK__SMSCampai__Tenan__16EE5E27] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSCampaign] CHECK CONSTRAINT [FK__SMSCampai__Tenan__16EE5E27]
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList]  WITH CHECK ADD  CONSTRAINT [FK__SMSCampai__Campa__55DFB4D9] FOREIGN KEY([CampaignId])
REFERENCES [dbo].[SMSCampaign] ([SMSCampaignId])
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList] CHECK CONSTRAINT [FK__SMSCampai__Campa__55DFB4D9]
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList]  WITH CHECK ADD  CONSTRAINT [FK__SMSCampai__Conta__54EB90A0] FOREIGN KEY([ContactListId])
REFERENCES [dbo].[Contact_List] ([Id])
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList] CHECK CONSTRAINT [FK__SMSCampai__Conta__54EB90A0]
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList]  WITH CHECK ADD  CONSTRAINT [FK__SMSCampai__Tenan__56D3D912] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSCampaign_ContactList] CHECK CONSTRAINT [FK__SMSCampai__Tenan__56D3D912]
GO
ALTER TABLE [dbo].[SMSConfiguration]  WITH CHECK ADD  CONSTRAINT [FK__SMSConfig__Tenan__257187A8] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSConfiguration] CHECK CONSTRAINT [FK__SMSConfig__Tenan__257187A8]
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([MapId])
REFERENCES [dbo].[SMSCampaign_ContactList] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSContactList_Status]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[SMSTemplates]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UniCampaignSession]  WITH CHECK ADD FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[User_Master]  WITH CHECK ADD  CONSTRAINT [FK__UserMaste__Tenan__6C040023] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[User_Master] CHECK CONSTRAINT [FK__UserMaste__Tenan__6C040023]
GO
ALTER TABLE [dbo].[UserMaster]  WITH CHECK ADD  CONSTRAINT [FK__UserMaste__Tenan__6C040022] FOREIGN KEY([TenantId])
REFERENCES [dbo].[Tenants] ([Id])
GO
ALTER TABLE [dbo].[UserMaster] CHECK CONSTRAINT [FK__UserMaste__Tenan__6C040022]
GO
/****** Object:  StoredProcedure [dbo].[ArchiveData_Call_Result_Table__Campaign_Id]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ArchiveData_Call_Result_Table__Campaign_Id]
AS
BEGIN
DECLARE @SQL NVARCHAR(MAX);
DECLARE @SELECT NVARCHAR(MAX);
DECLARE @WHERE NVARCHAR(MAX);
DECLARE @CAMPAIGN INT
SET @CAMPAIGN =(SELECT TOP 1 CampaignId FROM CampaignExtraDetails where IsActive=1 ORDER BY CampaignId)
WHILE @CAMPAIGN <= (SELECT TOP 1 CampaignId FROM CampaignExtraDetails where IsActive=1 ORDER BY CampaignId DESC)
BEGIN
IF EXISTS (SELECT * FROM SYS.TABLES WHERE name ='Call_Result_Table_'+CAST(@CAMPAIGN AS VARCHAR(10)))
BEGIN
     BEGIN TRANSACTION
                    BEGIN TRY

SET @SQL='INSERT INTO [UniCampaign_Historical].Call_Result_Table_'+CAST(@CAMPAIGN AS varchar(10))
SET @SELECT='  SELECT * FROM Call_Result_Table_'+CAST(@CAMPAIGN AS varchar(10))
SET @WHERE ='  WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))'
SET @SQL=@SQL+@SELECT+@WHERE
EXEC(@SQL)
PRINT(@SQL)

SET @SQL='DELETE FROM Call_Result_Table_'+CAST(@CAMPAIGN AS varchar(10))
SET @WHERE ='  WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))'
SET @SQL=@SQL+@WHERE
	EXEC(@SQL)
	PRINT(@SQL)
COMMIT TRANSACTION
END TRY
	BEGIN CATCH
	ROLLBACK
	END CATCH
	END
	SET @CAMPAIGN=@CAMPAIGN+1;

END
END





GO
/****** Object:  StoredProcedure [dbo].[ArchiveData_Contact_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ArchiveData_Contact_List]  
AS
BEGIN
    SET NOCOUNT ON
   
    BEGIN TRAN
	      
        insert  into [Historical] . [dbo].[Contact_List]
        select * FROM [Contact_List]
        WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while copying data to dbo.Contact_List', 16, 1)
            RETURN -1
        END

        DELETE FROM [Contact_List] WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))
		

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while deleting data from dbo.Contact_List', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
end





GO
/****** Object:  StoredProcedure [dbo].[ArchiveData_ContactList_ImportStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[ArchiveData_ContactList_ImportStatus]  

AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRAN
	  
        insert  into [Historical] . [dbo].[ContactList_ImportStatus]
        select * FROM [ContactList_ImportStatus]
        WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while copying data to dbo.Contactlist_Importstatus', 16, 1)
            RETURN -1
        END

        DELETE FROM [ContactList_ImportStatus] WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while deleting data from dbo.Contactlist_Importstatus', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
end





GO
/****** Object:  StoredProcedure [dbo].[ArchiveData_ContactMapAppendConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[ArchiveData_ContactMapAppendConfig]  

AS
BEGIN
    SET NOCOUNT ON
   
    BEGIN TRAN
	      
        insert  into [Historical] . [dbo].[ContactMapAppendConfig]
        select * FROM [ContactMapAppendConfig]  WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while copying data to dbo.[ContactMapAppendConfig]', 16, 1)
            RETURN -1
        END

        DELETE FROM [ContactMapAppendConfig] WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))
		

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while deleting data from dbo.[ContactMapAppendConfig]', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
end





GO
/****** Object:  StoredProcedure [dbo].[ArchiveData_ContactMapGroup]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[ArchiveData_ContactMapGroup]  

AS
BEGIN
    SET NOCOUNT ON
   
    BEGIN TRAN
        insert  into [Historical]. [dbo].[ContactMapGroup]
        select * FROM ContactMapGroup  WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while copying data to dbo.[ContactMapGroup]', 16, 1)
            RETURN -1
        END

        DELETE FROM ContactMapGroup WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while deleting data from dbo.[ContactMapGroup]', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
end





GO
/****** Object:  StoredProcedure [dbo].[ArchiveData_ContactMapGroupIteration]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  PROC [dbo].[ArchiveData_ContactMapGroupIteration]  

AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRAN
        insert  into [Historical] .[dbo].[ContactMapGroupIteration]
        select * FROM [ContactMapGroupIteration]
        WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while copying data to dbo.[ContactMapGroupIteration]', 16, 1)
            RETURN -1
        END

        DELETE FROM [ContactMapGroupIteration] WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while deleting data from dbo.[ContactMapGroupIteration]', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
end





GO
/****** Object:  StoredProcedure [dbo].[ArchiveData_Import_List_Table_Campaign_Id]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[ArchiveData_Import_List_Table_Campaign_Id]
AS
BEGIN
DECLARE @SQL NVARCHAR(MAX);
DECLARE @SELECT NVARCHAR(MAX);
DECLARE @WHERE NVARCHAR(MAX);
DECLARE @CAMPAIGN INT
SET @CAMPAIGN =(SELECT TOP 1 CampaignId FROM CampaignExtraDetails where IsActive=1 ORDER BY CampaignId)
WHILE @CAMPAIGN <= (SELECT TOP 1 CampaignId FROM CampaignExtraDetails where IsActive=1 ORDER BY CampaignId DESC)
BEGIN
IF EXISTS (SELECT * FROM SYS.TABLES WHERE name ='Import_List_Table_'+CAST(@CAMPAIGN AS VARCHAR(10)))
BEGIN
     BEGIN TRANSACTION
                    BEGIN TRY

SET @SQL='INSERT INTO [Historical].Import_List_Table_'+CAST(@CAMPAIGN AS varchar(10))
SET @SELECT='  SELECT * FROM Import_List_Table_'+CAST(@CAMPAIGN AS varchar(10))
SET @WHERE ='  WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))'
SET @SQL=@SQL+@SELECT+@WHERE
EXEC(@SQL)
PRINT(@SQL)

SET @SQL='DELETE FROM Import_List_Table_'+CAST(@CAMPAIGN AS varchar(10)) 
SET @WHERE ='  WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))'
SET @SQL=@SQL+@WHERE
	EXEC(@SQL)
	PRINT(@SQL)
COMMIT TRANSACTION
END TRY
	BEGIN CATCH
	ROLLBACK
	END CATCH
	END
	SET @CAMPAIGN=@CAMPAIGN+1;

END
END





GO
/****** Object:  StoredProcedure [dbo].[ArchiveData_Outbound_Call_Detail_1000]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROC [dbo].[ArchiveData_Outbound_Call_Detail_1000]  
AS
BEGIN
    SET NOCOUNT ON
    BEGIN TRAN
        insert  into [Historical] .[dbo].[Outbound_Call_Detail_1000]
        select * FROM Outbound_Call_Detail_1000
        WHERE DateTime < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while copying data to dbo.Outbound_Call_Detail_1000', 16, 1)
            RETURN -1
        END

        DELETE FROM [Outbound_Call_Detail_1000] WHERE DateTime < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while deleting data from dbo.Outbound_Call_Detail_1000', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
end





GO
/****** Object:  StoredProcedure [dbo].[Daily]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  PROCEDURE [dbo].[Daily] --6106,'23-04-2020 ','24-04-2020 '
	@campaign_id int,
	@StartDate datetime,
	@EndDate datetime
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT
                        COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL)) as Total,
						ISNULL(SUM(DialAttempts),0) as Dialed,
						(COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
						COUNT(IIF(IL.Status IN(3,4,6),1,NULL)) as Exclusion
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL  
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1 AND
			IL.CreatedOn between'+Cast(@StartDate as nvarchar)+' and '+Cast(@EndDate as nvarchar)+' '
						 ;
	execute sp_executesql @sql, N'@campaign_id int,@StartDate datetime,@EndDate datetime', @campaign_id,@StartDate,@EndDate;
END




GO
/****** Object:  StoredProcedure [dbo].[Daily_wise_campaign_statics]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[Daily_wise_campaign_statics]
@CampaignId INT,
@StartDate datetime,
@EndDate datetime
as
begin
DECLARE @sql nvarchar(MAX);
	SET @sql ='SELECT
       COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL)) as Total,
						ISNULL(SUM(DialAttempts),0) as Dialed,
	(COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))
	+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
	COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
	COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
	COUNT(IIF(IL.Status IN(3,4,6),1,NULL)) as Exclusion
	FROM Import_List_Table_'+CAST(@CampaignId AS nvarchar)+'  IL  
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
	where IL.CreatedOn BETWEEN @StartDate AND @EndDate'

	execute sp_executesql @sql, N'@CampaignId int','@StartDate datetime','@EndDate datetime', @CampaignId,@StartDate,@EndDate;

	end




GO
/****** Object:  StoredProcedure [dbo].[DailyNew]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[DailyNew] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = 'SELECT
          COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL)) as Total,
          ISNULL(SUM(DialAttempts),0) as Dialed,
	  (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
	  COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
	  COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
	  COUNT(IIF(IL.Status IN(3,4,6),1,NULL)) as Exclusion
	 FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL 
	 INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
	 INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
	INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1 AND
	IL.CreatedOn between dateadd(DAY, datediff(day, 0, getdate()),0) and GETDATE() ' ;
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END




GO
/****** Object:  StoredProcedure [dbo].[Delay_Import]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Delay_Import]
@DealerId int,
@search_term nvarchar(100) = null
as
begin


CREATE TABLE #XMLTable (CampaignList_Id int ,attribute varchar(30), operator varchar(30) , value varchar(30) )

INSERT INTO #XMLTable (CampaignList_Id,attribute , operator , value )
SELECT
s.CampaignList_Id,
m.c.value('@attribute', 'varchar(max)') as attribute ,
m.c.value('@operator', 'varchar(max)') as operator,
m.c.value('@value', 'varchar(max)') as value
from CampaignContact_List as s
outer apply s.Filters.nodes('filter/conditions/condition') as m(c)


SELECT CCL.CampaignList_Id , CED.Name as Campaign_Name , CL.Name as List_Name ,TS.value ,
delay=case when CLI.LastAttemptedOn!=null then (case when -DATEDIFF(MINUTE, getutcdate() , CLI.LastAttemptedOn)>15 then 1 else 0 end) else (case when -DATEDIFF(MINUTE, getutcdate() ,
CLI.PreProcessedOn)>15 then 1 else 0 end )end,
CLI.Lastattemptedon ,CCL.CreatedOn

from CampaignContact_List CCL
INNER JOIN Contact_List CL ON CCL.ListId=CL.Id
INNER JOIN ContactList_ImportStatus CLI ON CCL.CampaignList_Id=CLI.ListId
INNER JOIN CampaignExtraDetails CED ON CCL.CampaignId=CED.CampaignId
INNER JOIN #XMLTable TS ON CCL.CampaignList_Id=TS.CampaignList_Id
Where CCL.Status IN(1,5,7) 
AND CCL.IsActive=1 AND CL.IsActive=1 AND CED.IsActive=1
AND CL.DealerId= @DealerId  AND (@search_term IS NULL OR CED.NAME like '%'+@search_term+'%' )
AND CCL.CreatedOn between DateADD(Day,DateDIff(Day,0,GetDate()),0) AND GetDate()
DROP TABLE #XMLTable

end




GO
/****** Object:  StoredProcedure [dbo].[FetchingDatafrom]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[FetchingDatafrom]
as begin

	
	select distinct   CampaignId into #CLTemp from  [dbo].[CampaignExtraDetails] where [IsActive]=1
		   
	
	declare @CampaignId nvarchar(max) 
	declare @count int
    declare @sql nvarchar(max)
	
	select @count = (select count(distinct CampaignId) from #CLTemp)
	
	while @count>0
	begin
		
		select @CampaignId = (select distinct top 1 CampaignId from #CLTemp)
		
		set @sql='SELECT
						IT.CampaignId,
                        COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL)) as Total,
						ISNULL(SUM(DialAttempts),0) as Dialed,
						--COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dialed,
						(COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
						--COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Pending,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
						COUNT(IIF(IL.Status IN(3,4,6),1,NULL)) as Exclusion
						 FROM Import_List_Table_'+@CampaignId+'  IL  
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1 group by CampaignId'
						execute sp_executesql @sql;
						set @count =@count-1
						end
						end
	





GO
/****** Object:  StoredProcedure [dbo].[get_Campaign_detail]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[get_Campaign_detail]

as
  begin

    select c.Id,c.CampaignId, c.Name,c.TenantId,c.CreatedOn, c.LastUpdatedOn,c.IsActive, d.Dealercode,d.DealerName  from CampaignExtraDetails c
	inner join  Dealer d on c.DealerId=d.DealerId

  end


GO
/****** Object:  StoredProcedure [dbo].[get_contactlist]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[get_contactlist]
as
  
  declare @allcontact int=0;
  declare @activecontact int=0;
  declare @deactivecontact int=0

   begin

     set @allcontact= (select COUNT(*) from Contact_List);
	 set @activecontact=(select COUNT(*) from Contact_List where IsActive=1);
	 set @deactivecontact=(select COUNT(*) from Contact_List where IsActive=0);

	 select @allcontact as AllContactList,@activecontact as ActiveContactList,@deactivecontact as DeactiveContactList

   end


GO
/****** Object:  StoredProcedure [dbo].[Get_Contactlist_DrillDown_report]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[Get_Contactlist_DrillDown_report]
@Status nvarchar(100)=NULL
as
  begin
   
   if @Status='ALL' 
    begin
 
      SELECT   e.Name as ContactList,case when e.Purpose=1 then 'Voice'   when e.Purpose=2 then  'SMS' when e.Purpose=4 then 'Email' end as Purpose ,ILS.Name as Source ,X.Y.value('(filePath)[1]', 'VARCHAR(max)') as FilePath,
      X.Y.value('(delimiter)[1]', 'VARCHAR(max)') as Delimiter,
      X.Y.value('(headers)[1]', 'VARCHAR(max)') as Headers,D.DealerName,D.Dealercode,t.Name as TenantName,
	  e.CreatedOn, case when  e.IsActive=1 then 'True' else 'False' end as IsActive
	 
      FROM Contact_List e inner join Dealer d on e.DealerId=d.DealerId 	  
	 -- inner join DealerExtraDetails DE on d.DealerId=DE.DealerId 
	  inner join Tenants t on d.TenantId=t.Id
      OUTER APPLY e.Details.nodes('contactListDetails') as X(Y) 
      inner join ImportList_Source ILS on e.SourceId=ILS.Id 
		  
      end

    if @Status='Active'
	 begin


	 SELECT   e.Name as ContactList,case when e.Purpose=1 then 'Voice'   when e.Purpose=2 then  'SMS' when e.Purpose=4 then 'Email' end as Purpose ,ILS.Name as Source ,X.Y.value('(filePath)[1]', 'VARCHAR(max)') as FilePath,
      X.Y.value('(delimiter)[1]', 'VARCHAR(max)') as Delimiter,
      X.Y.value('(headers)[1]', 'VARCHAR(max)') as Headers,D.DealerName,D.Dealercode,t.Name as TenantName,
	  e.CreatedOn, case when  e.IsActive=1 then 'True' else 'False' end as IsActive
	 
      FROM Contact_List e inner join Dealer d on e.DealerId=d.DealerId 	  
	 -- inner join DealerExtraDetails DE on d.DealerId=DE.DealerId 
	  inner join Tenants t on d.TenantId=t.Id
      OUTER APPLY e.Details.nodes('contactListDetails') as X(Y) 
      inner join ImportList_Source ILS on e.SourceId=ILS.Id 

	  where e.IsActive=1

	 end


	 if @Status='Deactive'
	 begin

	 SELECT   e.Name as ContactList,case when e.Purpose=1 then 'Voice'   when e.Purpose=2 then  'SMS' when e.Purpose=4 then 'Email' end as Purpose ,ILS.Name as Source ,X.Y.value('(filePath)[1]', 'VARCHAR(max)') as FilePath,
      X.Y.value('(delimiter)[1]', 'VARCHAR(max)') as Delimiter,
      X.Y.value('(headers)[1]', 'VARCHAR(max)') as Headers,D.DealerName,D.Dealercode,t.Name as TenantName,
	  e.CreatedOn, case when  e.IsActive=1 then 'True' else 'False' end as IsActive
	 
      FROM Contact_List e inner join Dealer d on e.DealerId=d.DealerId 	  
	 -- inner join DealerExtraDetails DE on d.DealerId=DE.DealerId 
	  inner join Tenants t on d.TenantId=t.Id
      OUTER APPLY e.Details.nodes('contactListDetails') as X(Y) 
      inner join ImportList_Source ILS on e.SourceId=ILS.Id 

	  where e.IsActive=0

	 end

  end




GO
/****** Object:  StoredProcedure [dbo].[Get_Count_of_Campaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Get_Count_of_Campaign]

as 
   declare @all int=0;
   declare @active int=0;
   declare @Deactive int=0;

   begin


      set @all=(select count(c.CampaignId) from CampaignExtraDetails c);

	  set @active=(select count(c.CampaignId) from CampaignExtraDetails c where c.IsActive=1);

	  set @Deactive=(select count(c.CampaignId) from CampaignExtraDetails c where c.IsActive=0);

	  select @all as AllCampaigns,@active as ActiveCampaigns,@Deactive as DeActiveCampaigns;
   end


GO
/****** Object:  StoredProcedure [dbo].[get_Custom_Campaign_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[get_Custom_Campaign_List]

as
  begin


  select CampaignId,Name from CampaignExtraDetails where IsActive=1

  end


GO
/****** Object:  StoredProcedure [dbo].[get_DrillDown_Campaign_info]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[get_DrillDown_Campaign_info]

   @status nvarchar(100)=NULL

    as

	   begin

	     if @status='ALL' 

		   begin
           select c.CampaignId,c.Name as CampaignName,c.DealerId,c.TenantId,c.CreatedOn,d.DealerName,case when c.IsActive=1 then 'Active' else 'In-Active' end as IsActive from CampaignExtraDetails c
	        inner join  Dealer d on c.DealerId=d.DealerId

			end

         else if @status='Active'

		   begin
		    
			select c.CampaignId,c.Name as CampaignName,c.DealerId,c.TenantId,c.CreatedOn,d.DealerName,case when c.IsActive=1 then 'Active' else 'In-Active' end as IsActive from CampaignExtraDetails c
	        inner join  Dealer d on c.DealerId=d.DealerId where c.IsActive=1

		   end
          
		  else if @status='Deactive'

		   begin

		    select c.CampaignId,c.Name as CampaignName,c.DealerId,c.TenantId,c.CreatedOn,d.DealerName,case when c.IsActive=1 then 'Active' else 'In-Active' end as IsActive from CampaignExtraDetails c
	        inner join  Dealer d on c.DealerId=d.DealerId where c.IsActive=0

		   end

		   else 
		   begin

		    select c.CampaignId,c.Name as CampaignName,c.DealerId,c.TenantId,c.CreatedOn,d.DealerName,case when c.IsActive=1 then 'Active' else 'In-Active' end as IsActive from CampaignExtraDetails c
	        inner join  Dealer d on c.DealerId=d.DealerId

		   end

        end


GO
/****** Object:  StoredProcedure [dbo].[get_Exclusion_DNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[get_Exclusion_DNC]
as
  begin

    select COUNT(DNCId) as ExclusionDNC from CustomDNCMaruti where IsActive=1 and  CONVERT(varchar(10),CreatedOn,120)=CONVERT(varchar(10),GETDATE(),120)

	

  end


GO
/****** Object:  StoredProcedure [dbo].[get_global_dnc_count]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[get_global_dnc_count]

as

  begin

    select COUNT(DNCId) as GlobalDNC from Global_DNC where IsActive=1 and CONVERT(varchar(10),CreatedOn,120)=CONVERT(varchar(10),GETDATE(),120)

  end


GO
/****** Object:  StoredProcedure [dbo].[get_License_detail_so_far]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[get_License_detail_so_far]


as

  declare @totallicense int=0;
  declare @usedLicense int=0;
  begin

   set @totallicense= (select MAX(TotalLicense) from License_Master_UniAgent);
   set @usedLicense=(select count(UsedLicense) from License_Master_UniAgent where UsedLicense>0);


   select @totallicense as TotalLicense,@usedLicense as UsedLicense,case when @usedLicense<@totallicense then @usedLicense/@totallicense*100 else 0 end as LicenseUtilizedPer 

  end


GO
/****** Object:  StoredProcedure [dbo].[get_Rechurn_count_today]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[get_Rechurn_count_today]

as 

  begin

 --   create table #Campid(Campaid int);
	--drop table #Campid
	--insert into #Campid

	

	declare @total_attempted int=0;
	declare @total_attempted1 int=0;
	declare @rechurn1 int=0;
	declare @rechurn int=0;
	declare @Campid int=0;

	create table #value(total_attempted int,rechurn int,total int);
	declare importlist cursor 
	
	for 
	select CampaignId from CampaignExtraDetails;

	open importlist

	fetch next from importlist into  @Campid

	while @@FETCH_STATUS = 0 

	begin
	
	
	declare @Query nvarchar(max)=NULL;

	 set @Query='insert into  #value  select sum(DialAttempts) as DialAttempts,sum(ImportAttempts) as ImportAttempted,count(*) from Import_List_Table_'+cast(@Campid as varchar)    +  ' where ImportAttempts>0  and convert(varchar(10),ImportDateTime,120)=convert(varchar(10),getdate(),120)';
	execute sp_executesql @Query;
	 
     
	 fetch next from importlist into @Campid

	end
	

	
	CLOSE importlist  
--- deallocate the memory taken by cursor
DEALLOCATE importlist 


    select  isnull(sum(rechurn)-sum(total),0) as rechurn from #value;
	drop table #value;
  end


GO
/****** Object:  StoredProcedure [dbo].[GetCampaignBodyDetails]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[GetCampaignBodyDetails]
(
@campaignName varchar(200)
)
as
begin

select ScriptBody from CampaignExtraDetails ced inner join AgentScripts ass on ced.AgentScriptID=ass.AgentScriptID
where Name=@campaignName

end


GO
/****** Object:  StoredProcedure [dbo].[GetCampaignRealTimeStatus_CampaignWiseCountDashboard]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCampaignRealTimeStatus_CampaignWiseCountDashboard] --6764      
 @campaign_id int            
 AS BEGIN            
        
create table #temp1( CallingList nvarchar(max), TotalPending int);      
      
create table #temp2(CallingList nvarchar(max), Total int, Dialed int, Pending int, TotalConnect int,      
     TotalAbandoned int, Exclusion int, Duplicate int, TotalInvalid int, Rechurn int);      
      
      
 Declare @totalPending nvarchar(max);          
 set @totalPending = 'insert into #temp1(CallingList,TotalPending)  SELECT               
                      CL.Name as CallingList, (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9)        
   AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) TotalPending          
   FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL             
      INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId            
      INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId            
      INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1                  
      GROUP BY CL.Name'          
          
 execute sp_executesql @totalPending, N'@campaign_id int', @campaign_id ;            
          
 DECLARE @sql nvarchar(MAX);            
 SET @sql = ' insert into #temp2(CallingList, Total, Dialed, Pending, TotalConnect,TotalAbandoned,      
         Exclusion, Duplicate, TotalInvalid, Rechurn)       
 SELECT               
      CED.Name as CallingList,            
      COUNT(IIF(IL.Status IN(2,7,9,12,14,3,4,6),1,NULL)) as Total,            
      ISNULL(SUM(DialAttempts),0) as Dialed,            
      (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9)     
   AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,            
      COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,            
      COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,            
      COUNT(IIF(IL.Status IN(6),1,NULL)) as Exclusion,            
      COUNT(IIF(IL.Status IN(3),1,NULL)) as Duplicate,            
      COUNT(IIF(IL.Status IN(4),1,NULL)) as TotalInvalid,    
   case when isnull(sum(IL.ImportAttempts),0) > 0 then isnull(sum(IL.ImportAttempts),0) -1 else isnull(sum(IL.ImportAttempts),0) end as ReChurnAttempts            
      FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL     
  -- from Import_List_Table_6739 IL    
               
      INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId            
      INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId            
      INNER Join Contact_List CL on IT.ListId=CL.Id 
	  inner join CampaignExtraDetails CED on IT.CampaignId=CED.CampaignId where CL.IsActive=1            
      -- and cast(IL.CreatedOn as Date) = cast(getutcdate() as Date)    
	  

      GROUP BY CED.Name'         
         
   execute sp_executesql @sql, N'@campaign_id int', @campaign_id;            
        
  --select * from #temp1;      
  --select * from #temp2;      
        
  --7.9, 14      
      
     select t2.CallingList as Campaign, case when isnull(t2.Pending,0)> isnull(t2.Total,0) then (isnull(t2.Pending,0)  +  isnull(t2.Rechurn ,0))else (isnull(t2.Total,0))  end Total, isnull(t2.Dialed,0) Dialed, isnull(t2.Pending
,0) as Pending,    
                      isnull(TotalConnect,0) TotalConnect, isnull(TotalAbandoned,0)TotalAbandoned ,    
       isnull(Exclusion,0) Exclusion, isnull(Duplicate,0) Duplicate, isnull(TotalInvalid,0) TotalInvalid 
  from #temp2 t2     
        
      
  drop table #temp1;      
  drop table #temp2;      
        
       
  END 


GO
/****** Object:  StoredProcedure [dbo].[GetCampaignRealTimeStatus_ListWiseCountDashboard]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[GetCampaignRealTimeStatus_ListWiseCountDashboard] --6764      
 @campaign_id int            
 AS BEGIN            
        
create table #temp1( CallingList nvarchar(max), TotalPending int);      
      
create table #temp2(CallingList nvarchar(max), Total int, Dialed int, Pending int, TotalConnect int,      
     TotalAbandoned int, Exclusion int, Duplicate int, TotalInvalid int, Rechurn int);      
      
      
 Declare @totalPending nvarchar(max);          
 set @totalPending = 'insert into #temp1(CallingList,TotalPending)  SELECT               
                      CL.Name as CallingList, (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9)        
   AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) TotalPending          
   FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL             
      INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId            
      INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId            
      INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1                  
      GROUP BY CL.Name'          
          
 execute sp_executesql @totalPending, N'@campaign_id int', @campaign_id ;            
          
 DECLARE @sql nvarchar(MAX);            
 SET @sql = ' insert into #temp2(CallingList, Total, Dialed, Pending, TotalConnect,TotalAbandoned,      
         Exclusion, Duplicate, TotalInvalid, Rechurn)       
 SELECT               
      CL.Name as CallingList,            
      COUNT(IIF(IL.Status IN(2,7,9,12,14,3,4,6),1,NULL)) as Total,            
      ISNULL(SUM(DialAttempts),0) as Dialed,            
      (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9)     
   AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,            
      COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,            
      COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,            
      COUNT(IIF(IL.Status IN(6),1,NULL)) as Exclusion,            
      COUNT(IIF(IL.Status IN(3),1,NULL)) as Duplicate,            
      COUNT(IIF(IL.Status IN(4),1,NULL)) as TotalInvalid,    
   case when isnull(sum(IL.ImportAttempts),0) > 0 then isnull(sum(IL.ImportAttempts),0) -1 else isnull(sum(IL.ImportAttempts),0) end as ReChurnAttempts            
      FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL     
  -- from Import_List_Table_6739 IL    
               
      INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId            
      INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId            
      INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1            
      and cast(IL.CreatedOn as Date) = cast(getutcdate() as Date)            
      GROUP BY CL.Name'         
         
   execute sp_executesql @sql, N'@campaign_id int', @campaign_id;            
        
  --select * from #temp1;      
  --select * from #temp2;      
        
  --7.9, 14      
      
     select t1.CallingList, case when isnull(t1.TotalPending,0)> isnull(t2.Total,0) then (isnull(t1.TotalPending,0)  +  isnull(t2.Rechurn ,0))else (isnull(t2.Total,0))  end Total, isnull(t2.Dialed,0) Dialed, isnull(t1.TotalPending
,0) as Pending,    
                      isnull(TotalConnect,0) TotalConnect, isnull(TotalAbandoned,0)TotalAbandoned ,    
       isnull(Exclusion,0) Exclusion, isnull(Duplicate,0) Duplicate, isnull(TotalInvalid,0) TotalInvalid 
  from #temp1 t1 left join #temp2 t2    
  on t1.CallingList = t2.CallingList;    
        
      
  drop table #temp1;      
  drop table #temp2;      
        
       
  END 


GO
/****** Object:  StoredProcedure [dbo].[GetImportListDetails]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--ALTER PROCEDURE GetImportListDetails 'NPA_Recovery_Campaign','08273094020',71
CREATE PROCEDURE [dbo].[GetImportListDetails]
(
    @CampaignName VARCHAR(200),
    @PhoneNumber VARCHAR(200),
    @ListId int
)
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX);
    DECLARE @TableName NVARCHAR(255);

    -- Construct the dynamic table name based on the CampaignID
    SELECT @TableName = 'Import_List_Table_' + CAST(CampaignId AS NVARCHAR(50))
    FROM CampaignExtraDetails
    WHERE Name = @CampaignName;

    -- Construct the dynamic SQL query
    SET @SQL = '
    SELECT distinct IL.FirstName, IL.LastName, IL.FutureUseVarchar1, IL.FutureUseVarchar2, IL.FutureUseVarchar3,
           IL.FutureUseVarchar4, IL.FutureUseVarchar5, IL.FutureUseVarchar6, IL.FutureUseVarchar7, IL.FutureUseVarchar8,
		   IL.FutureUseVarchar9,IL.FutureUseVarchar10,IL.FutureUseVarchar11,IL.FutureUseVarchar12,IL.FutureUseVarchar13,
		   IL.FutureUseVarchar14,IL.FutureUseVarchar15,
           CED.AgentScriptID,AGS.ScriptBody
    FROM CampaignContact_List CCL
    INNER JOIN ' + QUOTENAME(@TableName) + ' IL ON CCL.CampaignList_Id = IL.MapId
    INNER JOIN CampaignExtraDetails CED ON CCL.CampaignId = CED.CampaignId
    INNER JOIN AgentScripts AS AGS ON CED.AgentScriptID = AGS.AgentScriptID
    WHERE CED.Name = @CampaignName AND IL.Phone01 = @PhoneNumber and IL.ImportList_Id=@ListId';

    -- Execute the dynamic SQL query
    EXEC sp_executesql @SQL, 
        N'@CampaignName VARCHAR(200), @PhoneNumber VARCHAR(200),@ListId int', 
        @CampaignName, @PhoneNumber,@ListId;
END;

GO
/****** Object:  StoredProcedure [dbo].[GetPreviewImportContact]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[GetPreviewImportContact] @data nvarchar(max)
as begin
declare @where nvarchar(max)
declare @query nvarchar(max)
declare @mainquery nvarchar(max)

set @query='SELECT TOP 1*
  FROM [dbo].[PreviewCampaignImportList]';

  set @where='where ('+@data+')'+'And (Status=2)';
  set @mainquery=@query+@where;
  exec(@mainquery);

end






GO
/****** Object:  StoredProcedure [dbo].[Identify_Not_Connected_Records]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE    [dbo].[Identify_Not_Connected_Records]
@StartDate DateTime=NULL,
@EndDate Datetime=NULL



AS 
BEGIN
DECLARE @SQL NVARCHAR(MAX);


SELECT  COUNT(Phone), Phone  FROM Outbound_Call_Detail_1000 
WHERE DateTime > @StartDate or @StartDate is null AND
DateTime < @EndDate OR @EndDate is null AND CallResult !=10 AND Status=12
GROUP BY Phone




end 










GO
/****** Object:  StoredProcedure [dbo].[Identify_Not_Connected_Records_13]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE   [dbo].[Identify_Not_Connected_Records_13]
@StartDate DateTime=NULL,
@EndDate Datetime=Null,
@CampaignId int
AS 
BEGIN
Declare @Sql nvarchar(max);
set @Sql = '
SELECT  distinct OCD.Phone , OCD.CallResult FROM Call_Result_Table_'+CAST(@CampaignId as nvarchar)+' CL 
INNER JOIN Import_List_Table_'+CAST(@CampaignId as nvarchar)+' IL ON CL.ImportList_Id=IL.ImportList_Id
INNER JOIN Outbound_Call_Detail_1000 OCD ON IL.ImportList_Id=OCD.AccountNumber
WHERE OCD.CallResult !=10 AND 
(OCD.DateTime >  @StartDate OR @StartDate is null)  and (OCD.DateTime <@EndDate  or @EndDate is null)'


EXEC sp_executesql @Sql ,N'@CampaignId int', @StartDate,@EndDate,@CampaignId;
end 







GO
/****** Object:  StoredProcedure [dbo].[import_License_info]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[import_License_info]
@totallicense int=0,
@usedlicense int=0
as
 begin

    insert into License_Master_UniAgent(TimeStamp,TotalLicense,UsedLicense) values(GETDATE(),@totallicense,@usedlicense)



 end


GO
/****** Object:  StoredProcedure [dbo].[Outbound_team_agent_status]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[Outbound_team_agent_status]

   as

   begin

        SELECT  EnterpriseName, agentname, 
					AgentState
FROM (SELECT Agent_Team.EnterpriseName,
		PQName = Skill_Group.EnterpriseName,
		skillgroup = Skill_Group.EnterpriseName,
		ServiceName = Service.EnterpriseName,
		Media = Media_Routing_Domain.EnterpriseName,
                agentname= Person.LastName + ', ' + Person.FirstName,
		AgentSkillID = Agent.SkillTargetID,
		AgentTeamSkillID = Agent_Team.AgentTeamID, 
		PriSupervisorSkillTargetID = Agent_Team.PriSupervisorSkillTargetID,
		SkillGroupID = Agent_Real_Time.SkillGroupSkillTargetID,
		AgentState = CASE Agent_Real_Time.AgentState  
			WHEN 0 THEN 'Logged Out' 
			WHEN 1 THEN 'Logged On' 
			WHEN 2 THEN 'Not Ready' 
			WHEN 3 THEN 'Ready' 
			WHEN 4 THEN 'Talking' 
			WHEN 5 THEN 'Work Not Ready' 
			WHEN 6 THEN 'Work Ready' 
			WHEN 7 THEN 'Busy Other' 
			WHEN 8 THEN 'Reserved'  
			WHEN 9 THEN 'Unknown' 
			WHEN 10 THEN 'Hold' 
			WHEN 11 THEN 'Active'  
			WHEN 12 THEN 'Paused' 
			WHEN 13 THEN 'Interrupted' 
			WHEN 14 THEN 'Not Active' 
			ELSE CONVERT(VARCHAR, Agent_Real_Time.AgentState) END, 
		phonetypetext = CASE Agent_Real_Time.PhoneType 
				When 0 THEN 'Not Mobile' 
				WHEN 1 THEN 'Call By Call' 
				WHEN 2 THEN 'Nailed Connection' 
				Else 'Not Applicable' END,    
		remotephonenumber = Agent_Real_Time.RemotePhoneNumber,
		Destination = CASE Agent_Real_Time.Destination 
				WHEN 1 THEN 'ACD' 
				WHEN 2 THEN 'Direct' 
				WHEN 3 THEN 'Auto Out' 
				WHEN 4 THEN 'Reserve' 
				WHEN 5 THEN 'Preview' 
				ELSE 'Not Applicable' END,
		Direction = CASE  Agent_Real_Time.Direction 
				WHEN 1 THEN 'In' 
				WHEN 2 THEN 'Out' 
							WHEN 3 THEN 'Other In'
			WHEN 4 THEN 'Other Out'
			WHEN 5 THEN 'Out Reserve'
			WHEN 6 THEN 'Out Preview'
			WHEN 7 THEN 'Out Predictive' 
				ELSE 'Not Applicable' END, 
		ReasonCode = Agent_Real_Time.ReasonCode , 
		Reason=(CASE WHEN Agent_Real_Time.ReasonCode = 0 THEN 'NONE'
					ELSE ISNULL((select ReasonText from Reason_Code where ReasonCode=Agent_Real_Time.ReasonCode),Agent_Real_Time.ReasonCode)  END),   
		Extension = Agent_Real_Time.Extension,
		LastStateChange = DATEDIFF(ss, Agent_Real_Time.DateTimeLastStateChange, CASE WHEN (DATEDIFF(ss, Agent_Real_Time.DateTimeLastStateChange, (SELECT NowTime from Controller_Time (nolock) )) < = 0 ) 
					THEN Agent_Real_Time.DateTimeLastStateChange 
					ELSE(SELECT NowTime FROM Controller_Time (nolock) ) END),
		LoginTime = Agent_Real_Time.DateTimeLogin,
		SupervAssist = Agent_Real_Time.RequestedSupervisorAssist,
		OnHold = Agent_Real_Time.OnHold,
		NetworkID = Agent_Real_Time.NetworkTargetID,
		Agent_Real_Time.DateTime,
		Date = Agent_Real_Time.DateTime,
		Agent_Real_Time.AgentStatus,
		Agent_Real_Time.CustomerPhoneNumber,
		Agent_Real_Time.CustomerAccountNumber,
		Agent_Real_Time.CampaignID,
		Agent_Real_Time.QueryRuleID,
		RoutableText = CASE WHEN Agent_Real_Time.Routable = 1 THEN 'Yes' ELSE 'No' END,
		Agent_Real_Time.DateTimeLastModeChange,
		Agent_Real_Time.CallInProgress,
		Agent_Real_Time.MaxTasks,
		AvailInMRDText = CASE WHEN Agent_Real_Time.AvailableInMRD = 0 THEN 'No' 
							  WHEN Agent_Real_Time.AvailableInMRD = 1 THEN 'Yes_ICM' 
							  WHEN Agent_Real_Time.AvailableInMRD = 2 THEN 'Yes_APP' 
							  ELSE 'No' END,
		Agent_Real_Time.DateTimeTaskLevelChange,
		Agent_Real_Time.RouterCallsQueueNow,
		Agent_Real_Time.RouterLongestCallQ,
		A1ID = ASGRT.Attribute1,
		A2ID = ASGRT.Attribute2,
		A3ID = ASGRT.Attribute3,
		A4ID = ASGRT.Attribute4,
		A5ID = ASGRT.Attribute5,
		A6ID = ASGRT.Attribute6,
		A7ID = ASGRT.Attribute7,
		A8ID = ASGRT.Attribute8,
		A9ID = ASGRT.Attribute9,
		A10ID = ASGRT.Attribute10,
        Attribute1 = A1.EnterpriseName,
		Attribute2 = A2.EnterpriseName,
		Attribute3 = A3.EnterpriseName,
		Attribute4 = A4.EnterpriseName,
		Attribute5 = A5.EnterpriseName,
		Attribute6 = A6.EnterpriseName,
		Attribute7 = A7.EnterpriseName,
		Attribute8 = A8.EnterpriseName,
		Attribute9 = A9.EnterpriseName,
		Attribute10 = A10.EnterpriseName  
	FROM Congestion_Control cc (nolock), Agent (nolock),
		 Person (nolock),   
		 Media_Routing_Domain (nolock),
		 Agent_Real_Time (nolock) 
			LEFT JOIN Service (nolock) ON Agent_Real_Time.ServiceSkillTargetID = Service.SkillTargetID  
			LEFT OUTER JOIN Agent_Skill_Group_Real_Time ASGRT (nolock) ON 
				(Agent_Real_Time.SkillTargetID = ASGRT.SkillTargetID 
				and Agent_Real_Time.SkillGroupSkillTargetID = ASGRT.SkillGroupSkillTargetID)
                        LEFT OUTER JOIN Attribute A1 (nolock) on ASGRT.Attribute1 = A1.AttributeID
			LEFT OUTER JOIN Attribute A2 (nolock) on ASGRT.Attribute2 = A2.AttributeID
			LEFT OUTER JOIN Attribute A3 (nolock) on ASGRT.Attribute3 = A3.AttributeID
			LEFT OUTER JOIN Attribute A4 (nolock) on ASGRT.Attribute4 = A4.AttributeID
			LEFT OUTER JOIN Attribute A5 (nolock) on ASGRT.Attribute5 = A5.AttributeID
			LEFT OUTER JOIN Attribute A6 (nolock) on ASGRT.Attribute6 = A6.AttributeID
			LEFT OUTER JOIN Attribute A7 (nolock) on ASGRT.Attribute7 = A7.AttributeID
			LEFT OUTER JOIN Attribute A8 (nolock) on ASGRT.Attribute8 = A8.AttributeID
			LEFT OUTER JOIN Attribute A9 (nolock) on ASGRT.Attribute9 = A9.AttributeID
			LEFT OUTER JOIN Attribute A10 (nolock) on ASGRT.Attribute10 = A10.AttributeID,
		 Agent_Team_Member (nolock),   
		 Agent_Team (nolock),   
		 Skill_Group (nolock)
	WHERE Agent_Real_Time.SkillGroupSkillTargetID = Skill_Group.SkillTargetID
	  and Agent.PersonID = Person.PersonID
	  and Media_Routing_Domain.MRDomainID = Agent_Real_Time.MRDomainID
          and Agent_Real_Time.MRDomainID = Skill_Group.MRDomainID
	  and Skill_Group.SkillTargetID NOT IN (SELECT BaseSkillTargetID FROM Skill_Group (nolock)  WHERE Priority > 0 AND Deleted ! = 'Y')
	  and Agent.SkillTargetID = Agent_Real_Time.SkillTargetID
	  and Agent.SkillTargetID = Agent_Team_Member.SkillTargetID
	  and Agent_Team_Member.AgentTeamID = Agent_Team.AgentTeamID

UNION

	SELECT Agent_Team.EnterpriseName,
		PQName = ISNULL(Precision_Queue.EnterpriseName, 'Not Applicable'), 
		skillgroup = convert(varchar,'Not Applicable'),
		ServiceName = convert(varchar,'Not Applicable'),
		Media = Media_Routing_Domain.EnterpriseName,
		agentname=Person.LastName + ', ' + Person.FirstName,
		AgentSkillID = Agent.SkillTargetID,
		AgentTeamSkillID = Agent_Team.AgentTeamID, 
		PriSupervisorSkillTargetID = Agent_Team.PriSupervisorSkillTargetID,
		SkillGroupID = Agent_Real_Time.SkillGroupSkillTargetID,
		AgentState = CASE Agent_Real_Time.AgentState  
					 WHEN 0 THEN 'Logged Out' 
					 WHEN 1 THEN 'Logged On' 
					 WHEN 2 THEN 'Not Ready' 
					 WHEN 3 THEN 'Ready' 
					 WHEN 4 THEN 'Talking' 
					 WHEN 5 THEN 'Work Not Ready' 
					 WHEN 6 THEN 'Work Ready' 
					 WHEN 7 THEN 'Busy Other' 
					 WHEN 8 THEN 'Reserved'  
					 WHEN 9 THEN 'Unknown' 
					 WHEN 10 THEN 'Hold' 
					 WHEN 11 THEN 'Active'  
					 WHEN 12 THEN 'Paused' 
					 WHEN 13 THEN 'Interrupted' 
					 WHEN 14 THEN 'Not Active' 
					 ELSE CONVERT(VARCHAR, Agent_Real_Time.AgentState) END, 
		phonetypetext = CASE Agent_Real_Time.PhoneType 
					When 0 THEN 'Not Mobile'
					WHEN 1 THEN 'Call By Call' 
					WHEN 2 THEN 'Nailed Connection' 
					Else 'Not Applicable' END,    
		remotephonenumber = Agent_Real_Time.RemotePhoneNumber,
		Destination = CASE Agent_Real_Time.Destination 
					WHEN 1 THEN 'ACD' 
					WHEN 2 THEN 'Direct' 
					WHEN 3 THEN 'Auto Out' 
					WHEN 4 THEN 'Reserve' 
					WHEN 5 THEN 'Preview' 
					ELSE 'Not Applicable' END, 
		Direction = CASE  Agent_Real_Time.Direction 
					WHEN 1 THEN 'In' 
					WHEN 2 THEN 'Out' 
			WHEN 3 THEN 'Other In'
			WHEN 4 THEN 'Other Out'
			WHEN 5 THEN 'Out Reserve'
			WHEN 6 THEN 'Out Preview'
			WHEN 7 THEN 'Out Predictive'
					ELSE 'Not Applicable' END, 
		ReasonCode = Agent_Real_Time.ReasonCode ,   
		Reason=(CASE WHEN Agent_Real_Time.ReasonCode = 0 THEN 'NONE'
					ELSE ISNULL((select ReasonText from Reason_Code where ReasonCode=Agent_Real_Time.ReasonCode),Agent_Real_Time.ReasonCode)  END),   
		Extension = Agent_Real_Time.Extension,
		LastStateChange = DATEDIFF(ss, Agent_Real_Time.DateTimeLastStateChange, CASE WHEN (DATEDIFF(ss, Agent_Real_Time.DateTimeLastStateChange, (SELECT NowTime from Controller_Time (nolock) )) < = 0 ) 
						THEN Agent_Real_Time.DateTimeLastStateChange 
						ELSE(SELECT NowTime FROM Controller_Time (nolock) ) END),
		LoginTime = Agent_Real_Time.DateTimeLogin,
		SupervAssist = Agent_Real_Time.RequestedSupervisorAssist ,
		OnHold = Agent_Real_Time.OnHold,
		NetworkID = Agent_Real_Time.NetworkTargetID,
		Agent_Real_Time.DateTime,
		Date = Agent_Real_Time.DateTime,
		Agent_Real_Time.AgentStatus,
		Agent_Real_Time.CustomerPhoneNumber,
		Agent_Real_Time.CustomerAccountNumber,
		Agent_Real_Time.CampaignID,
		Agent_Real_Time.QueryRuleID,
		RoutableText = CASE WHEN Agent_Real_Time.Routable = 1 THEN 'Yes' 
							ELSE 'No' END,
		Agent_Real_Time.DateTimeLastModeChange,
		Agent_Real_Time.CallInProgress,
		Agent_Real_Time.MaxTasks,
		AvailInMRDText = CASE WHEN Agent_Real_Time.AvailableInMRD = 0 THEN 'No' 
							  WHEN Agent_Real_Time.AvailableInMRD = 1 THEN 'Yes_ICM' 
							  WHEN Agent_Real_Time.AvailableInMRD = 2 THEN 'Yes_APP' 
							  ELSE 'No' END,
		Agent_Real_Time.DateTimeTaskLevelChange,
		Agent_Real_Time.RouterCallsQueueNow,
		Agent_Real_Time.RouterLongestCallQ,
		A1ID = ASGRT.Attribute1,
		A2ID = ASGRT.Attribute2,
		A3ID = ASGRT.Attribute3,
		A4ID = ASGRT.Attribute4,
		A5ID = ASGRT.Attribute5,
		A6ID = ASGRT.Attribute6,
		A7ID = ASGRT.Attribute7,
		A8ID = ASGRT.Attribute8,
		A9ID = ASGRT.Attribute9,
		A10ID = ASGRT.Attribute10,
        Attribute1 = A1.EnterpriseName,
		Attribute2 = A2.EnterpriseName,
		Attribute3 = A3.EnterpriseName,
		Attribute4 = A4.EnterpriseName,
		Attribute5 = A5.EnterpriseName,
		Attribute6 = A6.EnterpriseName,
		Attribute7 = A7.EnterpriseName,
		Attribute8 = A8.EnterpriseName,
		Attribute9 = A9.EnterpriseName,
		Attribute10 = A10.EnterpriseName 
	FROM Congestion_Control cc (nolock), Agent (nolock), 
		 Person (nolock),  
		 Media_Routing_Domain (nolock),
		 Agent_Real_Time  (nolock) 
			LEFT JOIN Service (nolock) ON Agent_Real_Time.ServiceSkillTargetID = Service.SkillTargetID   
			LEFT JOIN Precision_Queue (nolock) on Agent_Real_Time.PrecisionQueueID = Precision_Queue.PrecisionQueueID
			LEFT OUTER JOIN Agent_Skill_Group_Real_Time ASGRT (nolock) ON 
				(Agent_Real_Time.PrecisionQueueID = ASGRT.PrecisionQueueID 
				AND Agent_Real_Time.SkillTargetID = ASGRT.SkillTargetID )
            LEFT OUTER JOIN Attribute A1 (nolock) on ASGRT.Attribute1 = A1.AttributeID
			LEFT OUTER JOIN Attribute A2 (nolock) on ASGRT.Attribute2 = A2.AttributeID
			LEFT OUTER JOIN Attribute A3 (nolock) on ASGRT.Attribute3 = A3.AttributeID
			LEFT OUTER JOIN Attribute A4 (nolock) on ASGRT.Attribute4 = A4.AttributeID
			LEFT OUTER JOIN Attribute A5 (nolock) on ASGRT.Attribute5 = A5.AttributeID
			LEFT OUTER JOIN Attribute A6 (nolock) on ASGRT.Attribute6 = A6.AttributeID
			LEFT OUTER JOIN Attribute A7 (nolock) on ASGRT.Attribute7 = A7.AttributeID
			LEFT OUTER JOIN Attribute A8 (nolock) on ASGRT.Attribute8 = A8.AttributeID
			LEFT OUTER JOIN Attribute A9 (nolock) on ASGRT.Attribute9 = A9.AttributeID
			LEFT OUTER JOIN Attribute A10 (nolock) on ASGRT.Attribute10 = A10.AttributeID,
		 Agent_Team_Member (nolock),   
		 Agent_Team (nolock)
	WHERE ((Agent_Real_Time.SkillGroupSkillTargetID = 0) OR (Agent_Real_Time.SkillGroupSkillTargetID IS NULL)) 
		and	Agent.PersonID = Person.PersonID
		and Media_Routing_Domain.MRDomainID = Agent_Real_Time.MRDomainID
		and Agent.SkillTargetID = Agent_Real_Time.SkillTargetID
		and Agent.SkillTargetID = Agent_Team_Member.SkillTargetID 
		and Agent_Team_Member.AgentTeamID = Agent_Team.AgentTeamID ) C

LEFT OUTER JOIN
	(SELECT Person.LastName + ', ' + Person.FirstName as Supervisor, 
			SkillTargetID = Agent.SkillTargetID, 
			AgentTeamID = Agent_Team.AgentTeamID 
	   FROM Congestion_Control cc (nolock), Agent (nolock), 
			Person (nolock), 
			Agent_Team (nolock) 
	  WHERE Agent.SkillTargetID = Agent_Team.PriSupervisorSkillTargetID 
		AND Agent.PersonID = Person.PersonID) Supervisor 
    
on C.PriSupervisorSkillTargetID = Supervisor.SkillTargetID
and C.AgentTeamSkillID = Supervisor.AgentTeamID where AgentTeamSkillID IN (5022)
ORDER BY C.EnterpriseName, 
		 C.agentname,
		 C.AgentSkillID

end


GO
/****** Object:  StoredProcedure [dbo].[procedure_name]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROC [dbo].[procedure_name]
AS
BEGIN
    BEGIN TRAN
	      
        Insert into [UniCampaignE6_0].[dbo].[Call_Result_Table_5006]   
        Select * FROM [dbo].[Call_Result_Table_5006] 
       WHERE CreatedOn < DATEADD (DAY,-90, CONVERT (VARCHAR (10), GETDATE (),126))

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while copying data to table name ', 16, 1)
            RETURN -1
        END

        DELETE FROM [Call_Result_Table_5006] 
      WHERE CreatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))
		

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while deleting data from table name', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
END


GO
/****** Object:  StoredProcedure [dbo].[SP_Add_AgentScript]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  Create procedure [dbo].[SP_Add_AgentScript] 
	@tenant_id int,
	@scriptname nvarchar(100),
	@scriptBody nvarchar(MAX),
	@scriptEnable bit,
	@dealer_id int as
begin
	DECLARE @return_value int;
	declare @table Table (AgentScriptID int)
	insert into AgentScripts(TenantId,AgentScriptName,ScriptBody,Enable,IsActive,DealerId) 
	OUTPUT inserted.AgentScriptID into @table
	values(@tenant_id,@scriptname,@scriptBody,@scriptEnable,1,@dealer_id)
	Select * from @table;
end


GO
/****** Object:  StoredProcedure [dbo].[Sp_Add_CampaignContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_Add_CampaignContactList] @tenant_id int, @campaign_Id int,@listid int, @scheduleStart datetime ,
@timeZone nvarchar(100),@recurrence int,@recurrence_Interval numeric(10,2),@filterDuplicate bit,@filterDnc bit,
@keepheaders bit,@status int,@accountNumber nvarchar(100),@firstName nvarchar(100),
@lastName nvarchar(100) ,@phone01 nvarchar(100),@phone02 nvarchar(100)=null,@phone03 nvarchar(100),
@phone04 nvarchar(100),@phone05 nvarchar(100),@phone06 nvarchar(100),@phone07 nvarchar(100),@phone08 nvarchar(100),
@phone09 nvarchar(100),@phone10 nvarchar(100),@timeZone_bias nvarchar(100),@dstobserve nvarchar(100),@overwriteData bit,
@duplicate_rules xml,@target_country nvarchar(4),@recurrence_unit int = 2, @extra_details xml,
@extra_column1 nvarchar(255),
@extra_column2 nvarchar(255),
@extra_column3 nvarchar(255),
@extra_column4 nvarchar(255),
@extra_column5 nvarchar(255),
@extra_column6 nvarchar(255),
@extra_column7 nvarchar(255),
@extra_column8 nvarchar(255),
@extra_column9 nvarchar(255),
@extra_column10 nvarchar(255),
@extra_column11 nvarchar(255),
@extra_column12 nvarchar(255),
@extra_column13 nvarchar(255),
@extra_column14 nvarchar(255),
@extra_column15 nvarchar(255),
@extra_column16 nvarchar(255),
@requestType nvarchar(255),
@filters xml,
@dialingpriority int = null,
@ParentContactMap int = null
as
begin
declare @table Table (CampaignList_Id int)
insert into CampaignContact_List (TenantId,CampaignId,ListId, TargetCountry,ScheduleStart,TimeZone,Recurrence,Recurrence_Interval,FilterDuplicate,FilterDNC,KeepHeaders,Status,AccountNumber,FirstName,LastName,Phone01,Phone02,Phone03,Phone04,Phone05,Phone06,Phone07,Phone08,Phone09,Phone10,TimeZone_bias,DstObserve,CreatedOn,OverwriteData, RecurrenceUnit, DuplicateRules , ExtraDetails,FutureUseVarchar1,FutureUseVarchar2,FutureUseVarchar3,FutureUseVarchar4,FutureUseVarchar5,FutureUseVarchar6,FutureUseVarchar7,FutureUseVarchar8,FutureUseVarchar9,FutureUseVarchar10,FutureUseVarchar11,FutureUseVarchar12,FutureUseVarchar13,FutureUseVarchar14,FutureUseVarchar15,FutureUseVarchar16,RequestType,Filters,DialingPriority,ParentContactMap)
output inserted.CampaignList_Id into @table
values(@tenant_id,@campaign_Id, @listid,@target_country,@scheduleStart,@timeZone,@recurrence,@recurrence_Interval,@filterDuplicate,@filterDnc,@keepheaders,@status,@accountNumber,@firstName,@lastName,@phone01,@phone02,@phone03,@phone04,@phone05,@phone06,@phone07,@phone08,@phone09,@phone10,@timeZone_bias,@dstobserve,GETUTCDATE(),@overwriteData, @recurrence_unit,@duplicate_rules, @extra_details,@extra_column1,@extra_column2,@extra_column3,@extra_column4,@extra_column5,@extra_column6,@extra_column7,@extra_column8,@extra_column9,@extra_column10,@extra_column11,@extra_column12,@extra_column13,@extra_column14,@extra_column15,@extra_column16,@requestType,@filters,@dialingpriority,@ParentContactMap)
Select * from @table;
end





GO
/****** Object:  StoredProcedure [dbo].[SP_Add_EmailConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Add_EmailConfig] 
	@tenant_id int,@name nvarchar(100),
	@host nvarchar(MAX),@smtp_port int, @username nvarchar(MAX), @password nvarchar(MAX),
	@from_address nvarchar(MAX), @ssl bit , @dealer_id int as
begin
	DECLARE @return_value int;
	insert into EmailConfiguration (TenantId,Name,EmailHost,SMTPPort,EmailUsername,EmailPassword,FromAddress,IsSSL,IsActive,DealerId) 
	OUTPUT inserted.EmailConfigID
	values(@tenant_id,@name,@host,@smtp_port,@username,@password,@from_address,@ssl,1,@dealer_id)
end









GO
/****** Object:  StoredProcedure [dbo].[SP_Add_EmailTemplate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE procedure [dbo].[SP_Add_EmailTemplate] 
	@tenant_id int,
	@templatename nvarchar(100),
	@emailBody nvarchar(MAX),
	@dealer_id int as
begin
	DECLARE @return_value int;
	declare @table Table (EmailTemplateID int)
	insert into EmailTemplates(TenantId,EmailTemplateName,EmailBody,IsActive,DealerId) 
	OUTPUT inserted.EmailTemplateID into @table
	values(@tenant_id,@templatename,@emailBody,1,@dealer_id)
	Select * from @table;
end












GO
/****** Object:  StoredProcedure [dbo].[Sp_Add_ListForMultipleCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	
CREATE procedure [dbo].[Sp_Add_ListForMultipleCampaign]
 @tenant_id int,
  @campaignListconfig xml,
  @listid int, 
  @scheduleStart datetime ,
@timeZone nvarchar(100),
@recurrence int,@recurrence_Interval numeric(10,2),@filterDuplicate bit,@filterDnc bit,
@keepheaders bit,@status int,@accountNumber nvarchar(100),@firstName nvarchar(100),
@lastName nvarchar(100) ,@phone01 nvarchar(100),@phone02 nvarchar(100)=null,@phone03 nvarchar(100),
@phone04 nvarchar(100),@phone05 nvarchar(100),@phone06 nvarchar(100),@phone07 nvarchar(100),@phone08 nvarchar(100),
@phone09 nvarchar(100),@phone10 nvarchar(100),@timeZone_bias nvarchar(100),@dstobserve nvarchar(100),@overwriteData bit,
@duplicate_rules xml,@target_country nvarchar(4),@recurrence_unit int = 2
as
begin
declare @table Table (MapId int)
insert into ListForMultipleCampaign (TenantId,CampaignListConfig,ListId, TargetCountry,ScheduleStart,TimeZone,Recurrence,Recurrence_Interval,FilterDuplicate,FilterDNC,KeepHeaders,Status,AccountNumber,FirstName,LastName,Phone01,Phone02,Phone03,Phone04,Phone05,Phone06,Phone07,Phone08,Phone09,Phone10,TimeZone_bias,DstObserve,CreatedOn,OverwriteData, RecurrenceUnit, DuplicateRules)
output inserted.MapId into @table
values(@tenant_id,@campaignListconfig, @listid,@target_country,@scheduleStart,@timeZone,@recurrence,@recurrence_Interval,@filterDuplicate,@filterDnc,@keepheaders,@status,@accountNumber,@firstName,@lastName,@phone01,@phone02,@phone03,@phone04,@phone05,@phone06,@phone07,@phone08,@phone09,@phone10,@timeZone_bias,@dstobserve,GETUTCDATE(),@overwriteData, @recurrence_unit,@duplicate_rules)
Select * from @table;
 end









GO
/****** Object:  StoredProcedure [dbo].[SP_Add_New_DNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_Add_New_DNC] @tenant_id int, @Phone_Number nvarchar(150),@Campaign_Id int as
BEGIN
declare @table Table (DNCId int)
	INSERT INTO CustomDNC(PhoneNumber,CampaignId,TenantId, IsActive) output inserted.DNCId into @table
	VALUES(@Phone_Number,@Campaign_Id, @tenant_id,1)
	Select * from @table;
END




















GO
/****** Object:  StoredProcedure [dbo].[SP_Add_New_User]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Add_New_User] @user_name nvarchar(50), @user_password nvarchar(255),@user_role_id int,@user_tenant_id int as
BEGIN
declare @table Table (UserId int)
	INSERT INTO UserMaster(Username,Password,Role,TenantId) output inserted.UserId into @table VALUES(@user_name,@user_password,@user_role_id,@user_tenant_id);
	Select * from @table;
END

















GO
/****** Object:  StoredProcedure [dbo].[Sp_Add_PreviewCampaignContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


	
CREATE procedure [dbo].[Sp_Add_PreviewCampaignContactList] @tenant_id int, @campaign_Id int,@ListId int, @dealer_Id int,
@target_country nvarchar(4),@timeZone nvarchar(100),@filterDuplicate bit,@filterDnc bit,
@keepheaders bit,@status int,
@duplicate_rules xml,@headerMap xml
as
begin
declare @table Table (CampaignList_Id int)
insert into PreviewCampaignContact_List (TenantId,CampaignId,ListId, TargetCountry,TimeZone,FilterDuplicate,FilterDNC,KeepHeaders,Status,CreatedOn, DuplicateRules,HeaderMap,DealerId)
output inserted.CampaignList_Id into @table
values(@tenant_id,@campaign_Id, @ListId,@target_country,@timeZone,@filterDuplicate,@filterDnc,@keepheaders,@status,GETUTCDATE(),@duplicate_rules,@headerMap,@dealer_Id)
Select * from @table;
 end









GO
/****** Object:  StoredProcedure [dbo].[Sp_Add_RechurnPolicy]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Add_RechurnPolicy] 
@name nvarchar(max),
@description nvarchar(max)= null,
@Schedule int,
@isManual bit,
@dealerid int, 
@callDisposition_rules xml,
@Agentdisposition_Rule xml,
@Status int,
@dialAttempt int = null,
@dialAttemptCondition int = null


as
begin
declare @table Table (Id int)
insert into RechurnPolicy (Name,Description,Schedule,IsManual,CallResultsDetailsXml,AgentDispositionsDetailsXml,Status,CreatedOn,DealerId,DialAttempt,DialAttemptCondition)
output inserted.Id into @table
values(@name,@description, @Schedule,@isManual,@callDisposition_rules,@Agentdisposition_Rule,@Status,GETUTCDATE(),@dealerid,@dialAttempt,@dialAttemptCondition)
Select * from @table;
 end





GO
/****** Object:  StoredProcedure [dbo].[Sp_Add_RechurnPolicyMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Add_RechurnPolicyMap] 
@PolicyId int,
@Campaign int,
@ContactMap int,
@Status int
as
begin
declare @table Table (Id int)
insert into RechurnPolicyMap (PolicyId,Campaign,ContactMap,Status,CreatedOn)
output inserted.Id into @table
values(@PolicyId,@Campaign, @ContactMap,@Status,GETUTCDATE())
Select * from @table;
 end





GO
/****** Object:  StoredProcedure [dbo].[SP_Add_RecurrenceSchedule]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Add_RecurrenceSchedule]
	
	@name nvarchar(255),
	@description nvarchar(255),
	@scheduleType int,
	@frequency int,
	@recurenceInterval numeric(10,2),
	@recurenceUnit int,
	@startDateTime datetime,
	@endDateTime datetime,
	@status int
	

as begin
	declare @output table(Id int)
	insert into RecurrenceSchedule
		(Name,Description,ScheduleType,Frequency,RecurrenceInterval,RecurrenceUnit,StartDateTime,EndDateTime,Status,CreatedOn)
	output inserted.Id into @output
	values
		(@name,@description,@scheduleType,@frequency,@recurenceInterval,@recurenceUnit,@startDateTime,@endDateTime,@status,getutcDate());
	select * from @output
end






GO
/****** Object:  StoredProcedure [dbo].[SP_Add_SMSConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE procedure [dbo].[SP_Add_SMSConfig] 
	@tenant_id int,
	@configName nvarchar(100), 
	@type int,
	@configuration xml,
	@dealer_id int
	as
begin
	DECLARE @return_value int;
	declare @table Table (SMSConfigId int)
	insert into SMSConfiguration(TenantId,SMSConfigName,Configuration,Type,IsActive,CreatedOn,DealerId) 
	OUTPUT inserted.SMSConfigId into @table
	values(@tenant_id,@configName,@configuration,@type,1,GETDATE(),@dealer_id)
	Select * from @table;
end













GO
/****** Object:  StoredProcedure [dbo].[SP_Add_SMSTemplate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	  CREATE procedure [dbo].[SP_Add_SMSTemplate] 
	@tenant_id int,
	@templatename nvarchar(100),
	@smsMsg nvarchar(MAX),
	@dealer_id int
	 as
begin
	DECLARE @return_value int;
	declare @table Table (SMSTemplateID int)
	insert into SMSTemplates(TenantId,SMSTemplateName,SMSMessage,IsActive,DealerId) 
	OUTPUT inserted.SMSTemplateID into @table
	values(@tenant_id,@templatename,@smsMsg,1,@dealer_id)
	Select * from @table; 
end











GO
/****** Object:  StoredProcedure [dbo].[SP_AddBulkCallback]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_AddBulkCallback] @tenant_id int, @file_path nvarchar(300), @campaign int, @agent int, @overwrite bit, @delimiter char(1) as 
begin
declare @tbl Table(BulkId int)
	insert into BulkCallback (TenantId,FilePath, CampaignId, AgentSkillTargetId, OverwriteData,Delimiter) OUTPUT INSERTED.BulkId into @tbl values(@tenant_id,@file_path,@campaign, @agent, @overwrite,@delimiter)
	Select * from @tbl;
end
















GO
/****** Object:  StoredProcedure [dbo].[SP_AddCallback]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 Create procedure [dbo].[SP_AddCallback] 
@phonenumber nvarchar(50), @callbackDateTime datetime, @dealerId int, @campaignId int, @status int, @createdOn datetime
 as 
begin
declare @tbl Table(Id int)
	insert into CallbackMaster (PhoneNumber,CallbackScheduledDateTime,DealerId,CampaignId,Status,CreatedOn) 
	OUTPUT INSERTED.Id into @tbl values(@phonenumber,@callbackDateTime,@dealerId,@campaignId,@status,@createdOn)
	Select * from @tbl;
end


GO
/****** Object:  StoredProcedure [dbo].[SP_AddCallDetails]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddCallDetails]
@call_ID uniqueidentifier,
@state int,
@wrapUp_Code nvarchar(50)
as 
begin
declare @output table(CallID uniqueidentifier)
	insert into AgentCallDetails 
		(CallID,State,WrapupReasonCode,CreatedOn)
	output inserted.CallID into @output
	values
		(@call_ID,@state,@wrapUp_Code,GETUTCDATE());
	select * from @output
end








GO
/****** Object:  StoredProcedure [dbo].[SP_AddCampaignExtraDetails]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddCampaignExtraDetails] --1000,2124,'TestSP','<campaignDetails><identifier>AccountNumber</identifier><accountNumberPrefix /><firstNamePrefix /><lastNamePrefix /><dncglobal>false</dncglobal><dnctrai>false</dnctrai><defaultThresholdType>FixValue</defaultThresholdType><defaultThreshold>0</defaultThreshold><wrapUpValue /><dncWrapUpValue /><maxAttempts>3</maxAttempts><contactTableName>DL_6962_6957</contactTableName></campaignDetails>',1001
	@tenant_id int,							
	@campaign_Id int, 
	@name nvarchar(255), 
	@details xml,
	@dealer_Id int,
	@areacodes nvarchar(max)=null,
	@from_address nvarchar(200) = null,
	@to_address nvarchar(200) = null,
	@subject_line nvarchar(200) = null,
	@scheduled_days nvarchar (max)= null,
	@scheduled_time nvarchar(max)= null,
	@script_Id int = 0,
	@campaign_prefix nvarchar(200) = null
as begin
	--declare @output table(Id int)
	--insert into CampaignExtraDetails 
	--	(CampaignId,Name,Details,TenantId,DealerId)
	--output inserted.Id into @output
	--values
	--	(@campaign_Id,@name,@details,@tenant_id,@dealer_Id);
	--select * from @output
  SET @campaign_prefix = CASE 
                               WHEN @campaign_prefix = '' THEN NULL 
                               ELSE @campaign_prefix 
                           END;
if(not exists(select * from CampaignExtraDetails where TenantId = @tenant_id and CampaignId = @campaign_Id))
	begin
	declare @output table(Id int)
		insert into CampaignExtraDetails(CampaignId,Name,TenantId, Details,DealerId,Areacodes,AgentScriptID,CampaignPrefix) output inserted.Id into @output values (@campaign_Id,@name, @tenant_id,@details,@dealer_Id,@areacodes,@script_Id,@campaign_prefix);
	select * from @output
	end
	else
	begin
		update CampaignExtraDetails set Details = @details,LastUpdatedOn = GETUTCDATE(),Name=@name, DealerId=@dealer_Id, Areacodes=@areacodes,AgentScriptID=@script_Id,CampaignPrefix = @campaign_prefix  where CampaignId = @campaign_Id and TenantId = @tenant_id;
	end

	if(not exists(select * from Schedule_Mail where CampaignId = @campaign_Id))
	begin
	declare @output1 table(CampaignId int)
		insert into Schedule_Mail(CampaignId,FromAddress,ToAddress, SubjectLine,ScheduledDays,ScheduledTime) output inserted.CampaignId into @output1 values (@campaign_Id,@from_address, @to_address,@subject_line,@scheduled_days,@scheduled_time);
	select * from @output1
	end
	else
	begin
		update Schedule_Mail set FromAddress =@from_address, ToAddress=@to_address, SubjectLine=@subject_line , ScheduledDays = @scheduled_days,ScheduledTime = @scheduled_time where CampaignId = @campaign_Id ;
	end
end


GO
/****** Object:  StoredProcedure [dbo].[SP_AddCampaignGroup]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_AddCampaignGroup] 
	@tenant_id int, 
	@dealer_id int, 
	@name nvarchar(100)

as begin
	declare @output table(Id int)
	insert into GroupMaster 
		(Name,TenantId,CreatedOn,IsActive,DepartmentId)
	output inserted.Id into @output
	values
		(@name,@tenant_id,getutcdate(),1,@dealer_id);
	select * from @output
end


GO
/****** Object:  StoredProcedure [dbo].[SP_AddCBMConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddCBMConfig] @tenant_id int, @campaign_id int,@level int, @identifier nvarchar(20), @call_result_map xml, @wrapup_map xml, @max_attempts int as
begin
	insert into CBMConfig(TenantId, CampaignId,Level,IdentifierField, CallResultMap, WrapupMap, MaximumAttempts) 
	values(@tenant_id, @campaign_id,@level,@identifier, @call_result_map, @wrapup_map, @max_attempts)
end











GO
/****** Object:  StoredProcedure [dbo].[Sp_AddContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_AddContactList] @source_id int,@details xml , @name nvarchar(50), @purpose int = 0,@filter xml,@AutoGenerated bit, @dealerId int
as
begin
declare @table Table (Id int)
insert into Contact_List (SourceId, Details, Purpose, CreatedOn, Name,Filters,AutoGenerated,DealerId) output inserted.Id into @table
values(@source_id, @details,@purpose,GETUTCDATE(),@name, @filter,@AutoGenerated,@dealerId)
Select * from @table;
 end








GO
/****** Object:  StoredProcedure [dbo].[SP_AddContactListSequence]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddContactListSequence]     
 @tenant_id int,    
 @name nvarchar(100),    
 @campaign_id int,    
 @source_id int,    
 @template_path nvarchar(MAX) ,     
 @delimiter nvarchar(1),    
 @headers bit,    
 @filename_format nvarchar(MAX),    
 @daily_iterations int ,    
 @interval numeric(10,2),    
 @interval_unit int,    
 @interval_in_minutes numeric(10,2) ,    
 @start_time datetime =null ,    
 @time_zone nvarchar(255),    
 @target_country nvarchar(4),    
 @status int,    
 @filters xml = null,    
 @placeholder_map xml = null,    
 @header_map xml = null,    
 @dealer_id int,  
 @filter_duplicate bit = 0,  
 @duplicate_rules xml    
    
as begin    
 declare @output table (Id int)    
 insert into ContactListSequence     
 (    
  Name,TenantId,CampaignId,SourceId,TemplatePath,FileNameFormat,MaximumDailyIterations,Interval,IntervalUnit,IntervalInMinutes,    
  StartDateTime,TimeZone,TargetCountry,Status,PlaceholderMap,HeaderMap,Delimiter,Headers,Filters,DealerId,FilterDuplicate,DuplicateRules    
 )    
 output inserted.Id into @output    
 values(    
  @name,@tenant_id,@campaign_id,@source_id,@template_path,@filename_format,@daily_iterations,@interval,@interval_unit,@interval_in_minutes,    
  @start_time,@time_zone,@target_country,@status,@placeholder_map,@header_map,@delimiter,@headers,@filters,@dealer_id,@filter_duplicate,@duplicate_rules    
 )    
 select * from @output    
end 

GO
/****** Object:  StoredProcedure [dbo].[SP_AddContactListSequenceIteration]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddContactListSequenceIteration] 
	@sequence_id int,
	@map_id int, 
	@list_id int,
	@generated_filename nvarchar(max),
	@placeholder_map xml = null
as begin 
declare @tbl Table(Id int)
	insert into ContactListSequenceIteration
	(
		SequenceId,MapId, ListId, AutogeneratedFileName, PlaceholderMap
	)
	output inserted.Id into @tbl
	values(
		@sequence_id,@map_id, @list_id, @generated_filename, @placeholder_map
	)
	Select * from @tbl;

end










GO
/****** Object:  StoredProcedure [dbo].[SP_AddContactMapGroup]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

	
CREATE procedure [dbo].[SP_AddContactMapGroup] 
	@campaign_id int,
	@list_id int, 
	@schedule_start datetime,
	@time_zone nvarchar(100),
	@recurrence int,
	@recurrence_interval numeric(10,2),
	@recurrence_unit int = 2,
	@filter_duplicate bit,
	@filter_dnc bit,
	@keep_headers bit,
	@status int,
	@account_number nvarchar(100),
	@first_name nvarchar(100),
	@last_name nvarchar(100),
	@phone01 nvarchar(100),
	@phone02 nvarchar(100) = null,
	@phone03 nvarchar(100) = null,
	@phone04 nvarchar(100) = null,
	@phone05 nvarchar(100) = null,
	@phone06 nvarchar(100) = null,
	@phone07 nvarchar(100) = null,
	@phone08 nvarchar(100) = null,
	@phone09 nvarchar(100) = null,
	@phone10 nvarchar(100) = null,
	@timezone_bias nvarchar(100),
	@dst_observed nvarchar(100),
	@overwrite_data bit,
	@duplicate_rules xml,
	@target_country nvarchar(4),
	@extra_details xml,
	@extra_column1 nvarchar(255),
	@extra_column2 nvarchar(255),
	@extra_column3 nvarchar(255),
	@extra_column4 nvarchar(255),
	@extra_column5 nvarchar(255),
	@extra_column6 nvarchar(255),
	@extra_column7 nvarchar(255),
	@extra_column8 nvarchar(255),
	@extra_column9 nvarchar(255),
	@extra_column10 nvarchar(255),
	@extra_column11 nvarchar(255),
	@extra_column12 nvarchar(255),
	@extra_column13 nvarchar(255),
	@extra_column14 nvarchar(255),
	@extra_column15 nvarchar(255),
	@filters xml,
	@dialing_priority int,
	@group_details xml,
	@parent_id int = null
as
begin
declare @table Table (Id int)
insert into ContactMapGroup(
	CampaignId,
	ListId,
	TargetCountry,
	ScheduleStart,
	TimeZone,
	Recurrence,
	RecurrenceInterval,
	RecurrenceUnit,
	FilterDuplicate,
	FilterDNC,
	KeepHeaders,
	DialingPriority,
	ParentId,
	Status,
	GroupDetails,
	Phone01,
	AccountNumber,
	FirstName,
	LastName,
	Phone02,
	Phone03,
	Phone04,
	Phone05,
	Phone06,
	Phone07,
	Phone08,
	Phone09,
	Phone10,
	TimeZoneBias,
	DstObserved,
	OverwriteData,
	DuplicateRules,
	ExtraDetails,
	FutureUseVarchar1,
	FutureUseVarchar2,
	FutureUseVarchar3,
	FutureUseVarchar4,
	FutureUseVarchar5,
	FutureUseVarchar6,
	FutureUseVarchar7,
	FutureUseVarchar8,
	FutureUseVarchar9,
	FutureUseVarchar10,
	FutureUseVarchar11,
	FutureUseVarchar12,
	FutureUseVarchar13,
	FutureUseVarchar14,
	FutureUseVarchar15,
	Filters
	)
	output inserted.Id into @table
	values(
			@campaign_id,
			@list_id,
			@target_country,
			@schedule_start,
			@time_zone,
			@recurrence,
			@recurrence_interval,
			@recurrence_unit,
			@filter_duplicate,
			@filter_dnc,
			@keep_headers,
			@dialing_priority,
			@parent_id,
			@status,
			@group_details,
			@phone01,
			@account_number,
			@first_name,
			@last_name,
			@phone02,
			@phone03,
			@phone04,
			@phone05,
			@phone06,
			@phone07,
			@phone08,
			@phone09,
			@phone10,
			@timezone_bias,
			@dst_observed,
			@overwrite_data,
			@duplicate_rules,
			@extra_details,
			@extra_column1,
			@extra_column2,
			@extra_column3,
			@extra_column4,
			@extra_column5,
			@extra_column6,
			@extra_column7,
			@extra_column8,
			@extra_column9,
			@extra_column10,
			@extra_column11,
			@extra_column12,
			@extra_column13,
			@extra_column14,
			@extra_column15,
			@filters
		)
	Select * from @table;
 end



















GO
/****** Object:  StoredProcedure [dbo].[SP_AddContactMapGroupIteration]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddContactMapGroupIteration]
	
	@GroupId int,
	@MapId int,
	@CalculatedThreshold numeric(10,2)=null,
	@CalculatedThresholdType int=null,
	@TotalRecords int=null,
	@Details xml ,
	@Status int 

as begin
	declare @output table(Id int)
	insert into ContactMapGroupIteration
		(GroupId,MapId,CalculatedThreshold,CalculatedThresholdType,TotalRecords,CreatedOn,Details,Status)
	output inserted.Id into @output
	values
		(@GroupId,@MapId,@CalculatedThreshold,@CalculatedThresholdType,@TotalRecords,getutcDate(),@Details,@Status);
	select * from @output
end






GO
/****** Object:  StoredProcedure [dbo].[SP_AddCustomDNCMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE  procedure [dbo].[SP_AddCustomDNCMap] 
	@tenant_id int, 
	@filePath nvarchar(255),
	@campaignId int,
	@starttime time,
	@endtime time = null,
	@startdate datetime,
	@enddate datetime = null,
	@status int,
	@recurrence int,
	@recurrence_interval int = null,
	@dealerId int 
as begin
	declare @output table(Id int)
	insert into CustomDNCMapTable 
		(FilePath,CampaignId,StartDate,StartTime,EndTime,EndDate,Recurrence,RecurrenceInterval,TenantId,status,CreatedOn,IsActive,DealerId)
	output inserted.DNCMapId into @output
	values
		(@filePath,@campaignId,@startdate,@starttime,@endtime,@enddate,@recurrence,@recurrence_interval,@tenant_id,@status,getutcdate(),1,@dealerId);
	select * from @output
end




GO
/****** Object:  StoredProcedure [dbo].[SP_AddCustomDNCMaruti]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[SP_AddCustomDNCMaruti] 
	@tenant_id int, 
	@phoneNumber nvarchar(255),
	@campaignId int,
	@starttime time,
	@endtime time=null,
	@startdate datetime,
	@enddate datetime=null,
	@status int,
	@recurrence int=null,
	@recurrence_interval int = null,
	@dealerId int 

as begin
	declare @output table(Id int)
	insert into CustomDNCMaruti 
		(PhoneNumber,CampaignId,StartDate,StartTime,EndTime,EndDate,Recurrence,RecurrenceInterval,TenantId,status,CreatedOn,IsActive,DealerId)
	output inserted.DNCId into @output
	values
		(@phoneNumber,@campaignId,CAST (GETDATE() as Date),CAST (GETDATE() AS TIME),@endtime,@enddate,@recurrence,@recurrence_interval,@tenant_id,@status,GetUTCDate(),1,@dealerId);
	select * from @output
end




GO
/****** Object:  StoredProcedure [dbo].[SP_AddDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddDealer] 
	@tenant_id int, 
	@name nvarchar(100),
	@code nvarchar(100)
	
as begin
	declare @output table(Id int)
	insert into Dealer 
		(DealerName,TenantId,Dealercode)
	output inserted.DealerId into @output
	values
		(@name,@tenant_id,@code);
	select * from @output
end









GO
/****** Object:  StoredProcedure [dbo].[SP_AddDNCRule]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE
Procedure [dbo].[SP_AddDNCRule]   

	@dncRuleName nvarchar(255),
	@interOperatability nvarchar(255)
	
	as begin
	declare @table Table (DNCRuleId int)
	insert into DNCRule 
	(
	DNCName,CreatedOn,InterOperatability
	) output inserted.DNCId into @table
	values 
	(
		@dncRuleName,GETUTCDATE(),@interOperatability
	)
	Select * from @table;
end 






GO
/****** Object:  StoredProcedure [dbo].[SP_AddEmailCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_AddEmailCampaign]  
    @tenant_id int, 
	@name nvarchar(50), 
	@description nvarchar(255), 
	@state bit, 
	@email_config int,
	@start_time time, 
	@end_time time, 
	@max_batch_size int, 
	@timezone nvarchar(255) = null, 
	@start_date datetime = null, 
	@end_date datetime = null ,
	@dealer_id int
	as begin
	declare @table Table (EmailCampaignId int)
	insert into EmailCampaign 
	(
		Name, Description, State, EmailConfigId, StartDate, EndDate, StartTime, EndTime, 
		MaximumBatchSize, TimeZone, TenantId ,DealerId
	) output inserted.EmailCampaignId into @table
	values 
	(
		@name, @description, @state, @email_config, @start_date, @end_date, @start_time, @end_time,
		@max_batch_size, @timezone, @tenant_id,@dealer_id
	)
	Select * from @table;
end 













GO
/****** Object:  StoredProcedure [dbo].[SP_AddEmailContactMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddEmailContactMap] 
	@tenant_id int,
	@campaign_id int,
	@contact_list_id int,
	@email_column nvarchar(255),
	@attachment xml,
	@subject nvarchar(Max),
	@email_body nvarchar(MAX),
	@placeholders xml,
	@status int,
	@filter_duplicates bit,
	@recurrence_type int,
	@recurrence_interval numeric(10,0) = null,
	@recurrence_unit int = null,
	@recurrence_interval_hours numeric(10,0) = null,
	@recurrence_limit int = null,
	@recurrence_count int = null,
	@next_attempt datetime = null

as begin
declare @tbl Table(Id int)
	insert into EmailCampaign_ContactList 
		(TenantId,CampaignId,ContactListId,EmailColumn,EmailBody,Subject,Attachment,Placeholders,Status,FilterDuplicates,
			RecurrenceType,RecurrenceInterval,RecurrenceIntervalUnit,RecurrenceIntervalInHours,RecurrenceLimit,RecurrenceCount,NextAttemptDateTime)
	output inserted.Id into @tbl
	values(@tenant_id,@campaign_id,@contact_list_id,@email_column,@email_body,@subject,@attachment,@placeholders,@status,@filter_duplicates,
			@recurrence_type,@recurrence_interval,@recurrence_unit,@recurrence_interval_hours,@recurrence_limit,@recurrence_count,@next_attempt)
			Select * from @tbl;
end















GO
/****** Object:  StoredProcedure [dbo].[SP_AddEmailStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddEmailStatus]
	@tenant_id int,
	@map_id int,
	@total_records int,
	@invalid_records int,
	@duplicate_records int,
	@records_processed int,
	@end_position nvarchar(255) = null,
	@last_processed_on datetime = null
as begin
declare @table Table (Id int)
	insert into EmailContactList_Status(MapId,TotalRecords,InvalidRecords,DuplicateRecords,RecordsProcessed,EndPosition,LastProcessedOn,TenantId)
	output inserted.Id into @table
	values (@map_id, @total_records,@invalid_records, @duplicate_records, @records_processed,@end_position,@last_processed_on,@tenant_id)
	Select * from @table;
end












GO
/****** Object:  StoredProcedure [dbo].[SP_AddGlobal_DNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddGlobal_DNC] 
	@phone_number nvarchar(50),
	 @status int = null,
	 @rule_id int = null,
	 @agent_marked_on datetime = null

as begin
	declare @output table(Id [uniqueidentifier])
	if not exists(Select 1 from Global_DNC where PhoneNumber=@phone_number and IsActive=1)
	insert into Global_DNC 
		(PhoneNumber,Status,AgentMarkedOn,DNCRuleId,IsActive,CreatedOn)
	output inserted.DNCId into @output
	values
		(@phone_number,@status,@agent_marked_on,@rule_id,1,getutcdate());
	select * from @output
end


GO
/****** Object:  StoredProcedure [dbo].[SP_AddGlobal_DNCAutomation]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddGlobal_DNCAutomation] 
	@name nvarchar(50),
	 @folderPath nvarchar(100)

as begin
	declare @output table(Id [uniqueidentifier])
	insert into Global_DNCAutomation 
		(Name,FolderPath,IsActive,CreatedOn)
	output inserted.DNCId into @output
	values
		(@name,@folderPath,1,getutcdate());
	select * from @output
end


GO
/****** Object:  StoredProcedure [dbo].[SP_AddGlobalDNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddGlobalDNC] 
	@tenant_id int, 
	@phoneNumber nvarchar(255),
	@dncRuleId int
	 

as begin
	declare @output table(Id [uniqueidentifier])
	insert into GlobalDNC 
		(PhoneNumber,TenantId,IsActive,DNCRuleId)
	output inserted.DNCId into @output
	values
		(@phoneNumber,@tenant_id,1,@dncRuleId);
	select * from @output
end




GO
/****** Object:  StoredProcedure [dbo].[SP_AddGlobalDNCMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_AddGlobalDNCMap] 
	@filePath NVARCHAR(255),
	@status INT
AS
BEGIN
	DECLARE @output TABLE(Id INT)
	INSERT INTO GlobalDNCMap(FilePath,Status,CreatedOn)
	OUTPUT inserted.DNCMapId INTO @output VALUES(@filePath,@status,getutcdate());
	SELECT * FROM @output
END




GO
/****** Object:  StoredProcedure [dbo].[SP_AddHoliday]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_AddHoliday] 
	@tenant_id int, 
	@dealer_id int, 
	@name nvarchar(100), 
	@description nvarchar(255), 
	@start_date date,
	@start_time time,
	@end_time time,
	@end_date date,
	@recurrence int,
	@recurrence_interval numeric(10,2),
	@status int
as begin
	declare @output table(Id int)
	insert into Holiday 
		(Name,Description,StartDate,StartTime,EndTime,EndDate,Recurrence,RecurrenceInterval,TenantId,Status,CreatedOn,IsActive,DealerId)
	output inserted.HolidayId into @output
	values
		(@name,@description,@start_date,@start_time,@end_time,@end_date,@recurrence,@recurrence_interval,@tenant_id,@status,getutcdate(),1,@dealer_id);
	select * from @output
end











GO
/****** Object:  StoredProcedure [dbo].[SP_AddHolidayCampaignMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[SP_AddHolidayCampaignMap] 
	@tenant_id int, 
	@campaign_id int, 
	@holiday_id int, 
	@status int,
	@campaign_type varchar(255)
as begin
	declare @output table(Id int)
	insert into CampaignHoliday 
		(HolidayId,CampaignId,Status,TenantId,DateTime,CampaignType) 
	output inserted.Id into @output
	values
		(@holiday_id,@campaign_id,@status,@tenant_id,GETUTCDATE(),@campaign_type)
	select * from @output
end












GO
/****** Object:  StoredProcedure [dbo].[Sp_AddImportListSource]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_AddImportListSource] @tenant_id int, @name nvarchar(100),@type int,@configuration xml,@AutoGenerated bit,@dealerId int
as
begin
declare @table Table (Id int)
insert into ImportList_Source (Name, Type, Configuration, CreatedOn, TenantId,AutoGenerated,DealerId) OUTPUT INSERTED.Id into @table
values(@name,@type,@configuration,GETDATE(),@tenant_id,@AutoGenerated,@dealerId)
Select * from @table;
 end









GO
/****** Object:  StoredProcedure [dbo].[Sp_AddImportStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_AddImportStatus] 
	@list_id int,
	@totalRecordImported int,
	@totalDncFiltered int,
	@totalDuplicateFiltered int,
	@totalInvalid int,
	@attemptedOn datetime, 
	@finishIndex nvarchar(1000),
	@totalRecords int,
	@preprocessed_on datetime,
	@last_import_failed_records int,
	@status int
as
begin
	declare @output table(Id int)
	insert into ContactList_ImportStatus 
		(ListId, TotalRecordImported, TotalDncFiltered, TotalDuplicateFiltered, TotalInvalid,LastAttemptedOn, FinishIndex, TotalRecords,PreProcessedOn, LastImportFailedRecords,Status) 
	output inserted.CampaignList_Id into @output
	values
		(@list_id, @totalRecordImported, @totalDncFiltered, @totalDuplicateFiltered, @totalInvalid, @attemptedOn, @finishIndex,@totalRecords,@preprocessed_on,@last_import_failed_records, @status)
	select * from @output
 end









GO
/****** Object:  StoredProcedure [dbo].[Sp_AddImportStatusPreviewCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_AddImportStatusPreviewCampaign] 
	@list_id int,
	@totalRecordImported int,
	@totalDncFiltered int,
	@totalDuplicateFiltered int,
	@totalInvalid int,
	@attemptedOn datetime, 
	@finishIndex nvarchar(1000),
	@totalRecords int,
	@status int
as
begin
	declare @output table(Id int)
	insert into PreviewImportStatus 
		(ListId, TotalRecordImported, TotalDncFiltered, TotalDuplicateFiltered, TotalInvalid,LastAttemptedOn, FinishIndex, TotalRecords, DateTime,Status) 
	output inserted.CampaignList_Id into @output
	values
		(@list_id, @totalRecordImported, @totalDncFiltered, @totalDuplicateFiltered, @totalInvalid, @attemptedOn, @finishIndex,@totalRecords, getutcdate(),@status)
	select * from @output
 end









GO
/****** Object:  StoredProcedure [dbo].[SP_AddMultiAssignedContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_AddMultiAssignedContactList]
	@tenant_id int, 
	@name nvarchar(100), 
	@purpose int, 
	@sourceId int,
	@listDetails xml,
	@headermap xml,
	@country nvarchar(50),
	@timezone nvarchar(100),
	@duplicatefilter bit,
	@duplicateRule xml = null,
	@ExclusionList bit,
	@filter xml ,
	@status int,
	@extradetails xml

as begin
	declare @output table(Id int)
	insert into [MultiAssignedContactList]
		(Name,Purpose,SourceId,MultiListDetails,HeaderMap,Country,Timezone,DuplicateFilter,ExclusionList,Filters,CreatedOn,Status,ExtraDetails,TenantId,DuplicateRule)
	output inserted.MultiListId into @output
	values
		(@name,@purpose,@sourceId,@listDetails,@headermap,@country,@timezone,@duplicatefilter,@ExclusionList,@filter,getutcdate(),@status,@extradetails,@tenant_id,@duplicateRule);
	select * from @output
end









GO
/****** Object:  StoredProcedure [dbo].[SP_AddMultiContactListConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_AddMultiContactListConfig]
	@tenant_id int, 
	@name nvarchar(100), 
	@purpose int, 
	@sourceId int,
	@listDetails xml,
	@headermap xml,
	@country nvarchar(50),
	@timezone nvarchar(100),
	@duplicatefilter bit,
	@duplicateRule xml = null,
	@ExclusionList bit,
	@filter xml ,
	@status int,
	@extradetails xml,
	@scheduledStart datetime = null,
	@recurrence int,
	@recurrence_interval numeric(10,2) = null,
	@recurrenceUnit int ,
	@dealerId int


as begin
	declare @output table(Id int)
	insert into [MultiContactListConfig]
		(Name,Purpose,SourceId,MultiListDetails,HeaderMap,Country,Timezone,DuplicateFilter,ExclusionList,Filters,CreatedOn,Status,ExtraDetails,TenantId,DuplicateRule,Recurrence,Recurrence_Interval,RecurrenceUnit,ScheduleStart,DealerId)
	output inserted.MultiListId into @output
	values
		(@name,@purpose,@sourceId,@listDetails,@headermap,@country,@timezone,@duplicatefilter,@ExclusionList,@filter,getutcdate(),@status,@extradetails,@tenant_id,@duplicateRule,@recurrence,@recurrence_interval,@recurrenceUnit,@scheduledStart,@dealerId);
	select * from @output
end









GO
/****** Object:  StoredProcedure [dbo].[Sp_AddMultiImportStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[Sp_AddMultiImportStatus] 
	@list_id int,
	@totalRecordImported int,
	@totalDncFiltered int,
	@totalDuplicateFiltered int,
	@totalInvalid int,
	@attemptedOn datetime, 
	@finishIndex nvarchar(1000),
	@totalRecords int,
	@status int,
	@campainId int
as
begin
	declare @output table(Id int)
	insert into MultiContactList_ImportStatus 
		(ListId, TotalRecordImported, TotalDncFiltered, TotalDuplicateFiltered, TotalInvalid,LastAttemptedOn, FinishIndex, TotalRecords, DateTime,Status,CampaignId) 
	output inserted.CampaignList_Id into @output
	values
		(@list_id, @totalRecordImported, @totalDncFiltered, @totalDuplicateFiltered, @totalInvalid, @attemptedOn, @finishIndex,@totalRecords, getutcdate(),@status,@campainId)
	select * from @output
 end










GO
/****** Object:  StoredProcedure [dbo].[SP_AddNationalDNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddNationalDNC] 
	@tenant_id int, 
	@phoneNumber nvarchar(255),
	@dealerId int 

as begin
	declare @output table(Id int)
	insert into NationalDNC 
		(PhoneNumber,TenantId,DealerId,IsActive)
	output inserted.DNCId into @output
	values
		(@phoneNumber,@tenant_id,@dealerId,1);
	select * from @output
end









GO
/****** Object:  StoredProcedure [dbo].[SP_AddNewRole]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_AddNewRole]  
    @tenant_id int,
	@featureMap xml,
	@name nvarchar(100)
	as begin 
		declare @table Table (Id int)
		insert into Role_Master
		(
		TenantId,
		Name,
		FeatureMap
		)output inserted.RoleId into @table
		values
		(
		@tenant_id,
		@name,
		@featureMap
		)
		select * from @table;
	end









GO
/****** Object:  StoredProcedure [dbo].[SP_AddNewSession]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddNewSession] @user_id int, @tenant_id int, @start_time datetime, @extra_details nvarchar(600) as begin
	declare @tbl Table(SessionId int)
	insert into UniCampaignSession (UserId,TenantId,StartDateTime,ExtraDetails) output inserted.SessionId into @tbl values(@user_id,@tenant_id,@start_time,@extra_details)	
	select * from @tbl;
end











GO
/****** Object:  StoredProcedure [dbo].[SP_AddOrUpdate_Global_DNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddOrUpdate_Global_DNC]
	@phone_number nvarchar(50),
	@status int,
	@is_active bit = 1,
	@rule_id int = null,
	@agent_marked_on datetime = null
as begin

	declare @existing_id uniqueidentifier;
	select @existing_id = DNCId from Global_DNC where PhoneNumber = @phone_number;
	
	if(@existing_id is null)
	begin
		insert into Global_DNC 
			(PhoneNumber,Status,AgentMarkedOn,DNCRuleId,IsActive,CreatedOn)
		values
			(@phone_number,@status,@agent_marked_on,@rule_id,1,getutcdate());
	end
	else
	begin
		update Global_DNC set PhoneNumber = @phone_number,Status = @status, AgentMarkedOn = @agent_marked_on, DNCRuleId = @rule_id,IsActive = 1, LastUpdatedOn = getutcdate() where DNCId = @existing_id;
	end

end








GO
/****** Object:  StoredProcedure [dbo].[SP_AddPreviewCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_AddPreviewCampaign]  
    @tenant_id int,
	@dealer_id int,
	@name nvarchar(50), 
	@description nvarchar(255), 
	@state bit, 
	@start_time time, 
	@end_time time, 
	@time_zone nvarchar(255)=null,
	@target_country nvarchar(4) = null, 
	@start_date datetime = null, 
	@end_date datetime = null ,
	@no_skills int,
	@prefix nvarchar = null
	as begin
	declare @table Table (PreviewCampaignId int)
	insert into PreviewCampaign 
	(
		Name, Description, State, StartDate, EndDate, StartTime, EndTime, 
        TargetCountry, TimeZone,TenantId,DealerId,NoOfSkill,Prefix
	) output inserted.PreviewCampaignId into @table
	values 
	(
		@name, @description, @state, @start_date, @end_date, @start_time, @end_time,
	  @target_country, @time_zone,@tenant_id,@dealer_id,@no_skills,@prefix
	)
	Select * from @table;
end






GO
/****** Object:  StoredProcedure [dbo].[SP_AddRechurn_Policy]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddRechurn_Policy]
	
	@name nvarchar(255),
	@description nvarchar(255),
	@schedule int,
	@isManual bit,
	@callResultDeatilsXml xml,
	@status int,
	@dealerId int ,
	@agentDispositionsDeatilsXml xml

as begin
	declare @output table(Id int)
	insert into RechurnPolicy
		(Name,Description,Schedule,IsManual,CallResultsDetailsXml,Status,CreatedOn,DealerId,AgentDispositionsDetailsXml)
	output inserted.Id into @output
	values
		(@name,@description,@schedule,@isManual,@callResultDeatilsXml,@status,getUtcDate(),@dealerId,@agentDispositionsDeatilsXml);
	select * from @output
end






GO
/****** Object:  StoredProcedure [dbo].[SP_AddRechurnPolicy]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_AddRechurnPolicy] AS




GO
/****** Object:  StoredProcedure [dbo].[SP_AddRechurnPolicyMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddRechurnPolicyMap]
	
	@policyId int,
	@campaignId int,
	@ContactMapId int=null,
	@status int

as begin
	declare @output table(Id int)
	insert into RechurnPolicyMap
		(PolicyId,Campaign,ContactMap,CreatedOn,Status)
	output inserted.Id into @output
	values
		(@policyId,@campaignId,@ContactMapId,getutcDate(),@status);
	select * from @output
end






GO
/****** Object:  StoredProcedure [dbo].[SP_AddSMSCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_AddSMSCampaign]  
    @tenant_id int, 
	@name nvarchar(50), 
	@description nvarchar(255), 
	@state bit, 
	@sms_config int,
	@start_time time, 
	@end_time time, 
	@max_batch_size int, 
	@time_zone nvarchar(255)=null,
	@target_country nvarchar(4) = null, 
	@start_date datetime = null, 
	@end_date datetime = null ,
	@dealer_id int
	as begin
	declare @table Table (SMSCampaignId int)
	insert into SMSCampaign 
	(
		Name, Description, State, SMSConfigId, StartDate, EndDate, StartTime, EndTime, 
		MaximumBatchSize, TargetCountry, TimeZone,TenantId,DealerId
	) output inserted.SMSCampaignId into @table
	values 
	(
		@name, @description, @state, @sms_config, @start_date, @end_date, @start_time, @end_time,
		@max_batch_size, @target_country, @time_zone,@tenant_id,@dealer_id
	)
	Select * from @table;
end 













GO
/****** Object:  StoredProcedure [dbo].[SP_AddSMSContactMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddSMSContactMap] 
	@tenant_id int,
	@campaign_id int,
	@contact_list_id int,
	@phone_column nvarchar(255),
	@message nvarchar(MAX),
	@target_country nvarchar(4),
	@placeholders xml,
	@status int,
	@filter_duplicates bit,
	@recurrence_type int,
	@recurrence_interval numeric(10,0) = null,
	@recurrence_unit int = null,
	@recurrence_interval_hours numeric(10,0) = null,
	@recurrence_limit int = null,
	@recurrence_count int = null,
	@next_attempt datetime = null

as begin
	insert into SMSCampaign_ContactList 
		(TenantId,CampaignId,ContactListId,PhoneColumn,Message,TargetCountry,Placeholders,Status,FilterDuplicates,
			RecurrenceType,RecurrenceInterval,RecurrenceIntervalUnit,RecurrenceIntervalInHours,RecurrenceLimit,RecurrenceCount,NextAttemptDateTime)
	output inserted.Id
	values(@tenant_id,@campaign_id,@contact_list_id,@phone_column,@message,@target_country,@placeholders,@status,@filter_duplicates,
			@recurrence_type,@recurrence_interval,@recurrence_unit,@recurrence_interval_hours,@recurrence_limit,@recurrence_count,@next_attempt)
end














GO
/****** Object:  StoredProcedure [dbo].[SP_AddSMSStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AddSMSStatus]
	@tenant_id int,
	@map_id int,
	@total_records int,
	@invalid_records int,
	@duplicate_records int,
	@records_processed int,
	@end_position nvarchar(255) = null,
	@last_processed_on datetime = null
as begin
declare @table Table (Id int)
	insert into SMSContactList_Status (MapId,TotalRecords,InvalidRecords,DuplicateRecords,RecordsProcessed,EndPosition,LastProcessedOn,TenantId)
	output inserted.Id into @table
	values (@map_id, @total_records,@invalid_records, @duplicate_records, @records_processed,@end_position,@last_processed_on,@tenant_id)
	Select * from @table;
end











GO
/****** Object:  StoredProcedure [dbo].[Sp_AddTenant]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_AddTenant] @name nvarchar(100),@configuration xml
as
begin
declare @table Table (Id int)
insert into Tenants (Name, Configuration) OUTPUT INSERTED.Id into @table
values(@name,@configuration)
Select * from @table;
 end















GO
/****** Object:  StoredProcedure [dbo].[SP_AddUserMaster]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_AddUserMaster]  
    @tenant_id int,
	@role_id int,
	@user_name nvarchar(100),
	@dealer_Id int,
	@password nvarchar(50)
	as begin 
		declare @table Table (Id int)
		insert into User_Master
		(
		UserName,
		TenantId,
		RoleId,
		DealerId,
		Password,
		PasswordUpdatedOn
		)output inserted.UserId into @table
		values
		(
		@user_name,
		@tenant_id,
		@role_id,
		@dealer_Id,
		@password,
		getutcdate()


		)
	end








GO
/****** Object:  StoredProcedure [dbo].[SP_AddWrapupReasonCode]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[SP_AddWrapupReasonCode] 
@tenant_id int,
@wrapUpCode_Name nvarchar(50),
@description Nvarchar(255),
@dealer_id int
as
begin
declare @output table(Id int)
	insert into PreviewWarpReasonCode 
		(WrapUpCodeName,TenantId,Description,CreatedOn,DealerId)
	output inserted.WrapupCodeId into @output
	values
		(@wrapUpCode_Name,@tenant_id,@description,GETUTCDATE(),@dealer_id);
	select * from @output
end












GO
/****** Object:  StoredProcedure [dbo].[sp_Archeieve]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [dbo].[sp_Archeieve]
AS
BEGIN
    BEGIN TRAN
	  
	  --select count(*) from Contact_List order by DateTime desc

	  --alter table [Call_Result_Table_5042] check constraint all

        Insert into  [UniCampaign_DB_Historical].[dbo].[Call_Result_Table_5067]
        Select * FROM [dbo].Call_Result_Table_5067 
       WHERE LastUpdatedOn <  DATEADD (DAY,-90, CONVERT (VARCHAR (10), GETDATE (),126))
	   
	  
	

	 Insert into  [UniCampaign_DB_Historical].[dbo].[Import_List_Table_5067]   
       Select * FROM [dbo].[Import_List_Table_5067] 
      WHERE LastUpdatedOn < DATEADD (DAY,-90, CONVERT (VARCHAR (10), GETDATE (),126))
	   

	
        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while copying data to table name ', 16, 1)
            RETURN -1
        END

  
	
	  alter table [Import_List_Table_5067] check  constraint all
	-- go
	   alter table [Call_Result_Table_5067] check constraint all
	   --5067
	---   go

	   DELETE FROM [dbo].[Import_List_Table_5067]
      WHERE LastUpdatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))

	
	  --[sp_Archeieve]
	  
	   --check constraint  --FK__Call_Resu__Impor__421E42AF
	   --FK__Call_Resu__Impor__4B0826A8
	   --FK__Call_Resu__Impor__5426B137
	  DELETE FROM [dbo].Call_Result_Table_5067 
      WHERE LastUpdatedOn < DATEADD(DAY,-90,CONVERT(VARCHAR(10),GETDATE(),126))
		

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured while deleting data from table name', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
END






GO
/****** Object:  StoredProcedure [dbo].[SP_Audit_Trail]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Audit_Trail] @tenant_id int, @user_id int, @operation nvarchar(255), @description nvarchar(255),@details xml= null as
begin
	insert into Audit_Trail (TenantId,UserId,ActionName,Description,DateTime,Details) values (@tenant_id,@user_id,@operation,@description,getutcdate(),@details)
end















GO
/****** Object:  StoredProcedure [dbo].[SP_AuthenticateUser]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AuthenticateUser] @Username nvarchar(50), @TenantId int as begin
select * from UserMaster where Username = @Username and TenantId = @TenantId
end














GO
/****** Object:  StoredProcedure [dbo].[SP_AuthenticateUser_Master]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_AuthenticateUser_Master] @Username nvarchar(50), @TenantId int ,@DealerId int as begin
select u.*,r.Name as RoleName,d.DealerName as DealerName from User_Master u inner join Dealer d on u.DealerId=d.DealerId inner join Role_Master r on u.RoleId=r.RoleId where u.UserName = @Username and u.TenantId = cast(@TenantId as nvarchar) and u.DealerId=cast(@DealerId as nvarchar);
end









GO
/****** Object:  StoredProcedure [dbo].[SP_BigDataDNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_BigDataDNC] @filePath varchar(255) ,@filePath_Fmt varchar(255)as
begin
declare @query nvarchar(max);
BEGIN TRY
    BEGIN TRANSACTION
set @query =' INSERT [dbo].[DNC_Test] ([PhoneNumber], [IsActive]) SELECT [PhoneNumber] ,[IsActive]=1
FROM OPENROWSET (BULK  ''' + @filePath + ''',FORMATFILE=''' + @filePath_Fmt + ''') as BulkLoadFile'
exec(@query);
  COMMIT TRANSACTION
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
END CATCH
end










GO
/****** Object:  StoredProcedure [dbo].[SP_Call_Wrapup_Stats]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Call_Wrapup_Stats]


as begin

    
          select sum(A.CallCompleted) as 'Call Completed',sum(A.Appointment) as Appointment,sum(A.DNC) as DNC, SUM(A.DoNotCall) as 'Do Not Call',sum(A.NoAnswer) as 'No Answer', Sum(A.PromiseToPay) as 'Promise To Pay',Sum(A.VoiceDistoration) as 'Voice Distoration',Sum(A.WarmCustomer) as 'Warm Customer'
		  
		  from
		  (
       select case when OCD.WrapupData='Call Completed' then COUNT(*) else 0 end as 'CallCompleted',
	   case when OCD.WrapupData='Appointment'  then COUNT(*) else 0 end as 'Appointment',
	   case when OCD.WrapupData='DNC' then COUNT(*) else 0  end as 'DNC',
	   case when OCD.WrapupData='Do Not Call' then COUNT(*) else 0 end as 'DoNotCall',
	   case when OCD.WrapupData='No Answer' then COUNT(*) else 0  end as 'NoAnswer',
	   case when OCD.WrapupData='Promise To Pay' then COUNT(*) else 0 end as 'PromiseToPay',
	   case when OCD.WrapupData='Voice Distoration' then Count(*) else 0 end as 'VoiceDistoration',
	   case when OCD.WrapupData='Warm Customer' then COUNT(*) else 0 end as 'WarmCustomer'	   	  	   
	   from Outbound_Call_Detail_1000 OCD(nolock) inner join CampaignExtraDetails CED (nolock) on OCD.CampaignID=CED.CampaignId
	   --where Convert(varchar(10),OCD.DateTime,120)=Convert(varchar(10),GETDATE(),120)
	   group by OCD.WrapupData
	   ) A

end


GO
/****** Object:  StoredProcedure [dbo].[SP_Call_Wrapup_Stats_by_Agents]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Call_Wrapup_Stats_by_Agents]

  as

     begin
	  
       select OCD.AgentName,CED.Name as Campaigns,
	   case when OCD.WrapupData='Call Completed' then COUNT(*) else 0 end as 'Call Completed',
	   case when OCD.WrapupData='Appointment'  then COUNT(*) else 0 end as 'Appointment',
	   case when OCD.WrapupData='DNC' then COUNT(*) else 0  end as 'DNC',
	   case when OCD.WrapupData='Do Not Call' then COUNT(*) else 0 end as 'Do Not Call',
	   case when OCD.WrapupData='No Answer' then COUNT(*) else 0  end as 'No Answer',
	   case when OCD.WrapupData='Promise To Pay' then COUNT(*) else 0 end as 'Promise To Pay',
	   case when OCD.WrapupData='Voice Distoration' then Count(*) else 0 end as 'Voice Distoration',
	   case when OCD.WrapupData='Warm Customer' then COUNT(*) else 0 end as 'Warm Customer'	   	  	   
	   from Outbound_Call_Detail_1000 OCD(nolock) INNER join CampaignExtraDetails CED (nolock) on OCD.CampaignID=CED.CampaignId
	   where Convert(varchar(10),OCD.DateTime,120)=Convert(varchar(10),GETDATE(),120)
	   group by OCD.AgentName,CED.Name,OCD.WrapupData 

     end


GO
/****** Object:  StoredProcedure [dbo].[Sp_Campaign_ImportList_report]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  procedure [dbo].[Sp_Campaign_ImportList_report]

as 

  begin

 --   create table #Campid(Campaid int);
	--drop table #Campid
	--insert into #Campid

	

	declare @total_attempted int=0;
	declare @total_attempted1 int=0;
	declare @rechurn1 int=0;
	declare @rechurn int=0;
	declare @Campid int=0;

	create table #value(Phone01 nvarchar(50),AccountNumber nvarchar(100),FirstName nvarchar(100),lastname nvarchar(100),AgentName nvarchar(200),CallResult nvarchar(500),Status nvarchar(500),DateTime datetime);
	declare importlist cursor 
	
	for 
	select CampaignId from CampaignExtraDetails;

	open importlist

	fetch next from importlist into  @Campid

	while @@FETCH_STATUS = 0 

	begin
	
	
	declare @Query nvarchar(max)=NULL;

	 set @Query='insert into  #value  select Phone01,AccountNumber,FirstName,LastName,AgentName,
CallResultName = CASE CallResult WHEN 2 THEN ''Error condition while dialing'' 
when 0 then ''Pending''
when 2 then ''ErrorConditionWhileDialing''
when 29 then ''NotSupportedByVoiceGateway''
when 30 then ''NotAuthorizedByVoiceGateway''
when 31 then ''InvalidSipToVG''
when 32 then ''CallCancelledByLostConnection''
WHEN 3 THEN ''Number reported not in service by network''
WHEN 4 THEN ''No ringback from network when dial attempted''
WHEN 5 THEN ''Operator intercept returned from network when dial attempted''
WHEN 6 THEN ''No dial tone when dialer port went off hook''
WHEN 7 THEN ''Number reported as invalid by the network''
WHEN 8 THEN ''Customer phone did not answer''
WHEN 9 THEN ''Customer phone was busy''
WHEN 10 THEN ''Customer answered and was connected to agent''
WHEN 11 THEN ''Fax machine detected''
WHEN 12 THEN ''Answering machine detected''
WHEN 13 THEN ''Dialer stopped dialing customer due to lack of agents or network stopped dialing before it was complete''
WHEN 14 THEN ''Customer requested callback''
WHEN 16 THEN ''Call was abandoned by the dialer due to lack of agents''
WHEN 17 THEN ''Failed to reserve agent for personal callback''
WHEN 18 THEN ''Agent has skipped or rejected a preview call''
WHEN 19 THEN ''Agent has skipped or rejected a preview call with the close option''
WHEN 20 THEN ''Customer has been abandoned to an IVR''
WHEN 21 THEN ''Customer dropped call within configured abandoned time''
WHEN 22 THEN ''Mostly used with TDM switches - network answering machine, such as a network voicemail''
WHEN 23 THEN ''Number successfully contacted but wrong number''
WHEN 24 THEN ''Number successfully contacted but reached the wrong person''
WHEN 25 THEN ''Dialer has flushed this record due to a change in the skillgroup. the campaign, etc.''
WHEN 26 THEN ''The number was on the do not call list''
WHEN 27 THEN ''Call disconnected by the carrier or the network while ringing''
WHEN 28 THEN ''Dead air or low voice volume call''
ELSE ''Unknown Call Result'' END,
Status=case Status when 1 then ''Pending''
when 2 then ''Active''
when 3 then ''Duplicate''
when 4 then ''Invalid'' 
when 5 then ''Valid''
when 6 then ''Excluded'' 
when 7 then ''Retry''
when 8 then ''Processing''
when 9 then ''Imported''
when 10 then ''Failed''
when 11 then ''Deleted''
when 12 then ''Completed'' 
when 13 then ''Expired''
when 14 then ''InActive''
when 15 then ''SkippedOrRejected'' 
when 16 then ''NotFoundCallResult''
when 17 then ''Schedule''
when 18 then ''DailerAutoRetry'' 
when 20 then ''GlobalDuplicate'' end ,ImportDateTime  from Import_List_Table_'+cast(@Campid as varchar)    +  ' where convert(varchar(10),ImportDateTime,120)=convert(varchar(10),getdate(),120) ';
	execute sp_executesql @Query;
	 
     
	 fetch next from importlist into @Campid

	end
	

	
	CLOSE importlist  
--- deallocate the memory taken by cursor
DEALLOCATE importlist 


    select  * from #value;
	drop table #value;
  end


GO
/****** Object:  StoredProcedure [dbo].[SP_CheckListStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_CheckListStatus] 
	@campaign_id INT,
	@list_id INT
	
AS BEGIN	
DECLARE @Total INT
	SET @Total = (SELECT COUNT(*) FROM CampaignContact_List map
				 INNER JOIN Contact_List list ON list.Id = map.ListId
				 INNER JOIN ImportList_Source src ON src.Id = list.SourceId
				 INNER JOIN Dealer dealer ON dealer.DealerId = list.DealerId
	             WHERE list.IsActive = 1 AND map.Status NOT IN(8) AND src.IsActive = 1 AND dealer.IsActive = 1 
				 AND map.ListId= @list_id AND map.CampaignId=@campaign_id)
		SELECT Status, StatusSum FROM (
		SELECT map.Status AS Status, COUNT(map.Status) AS StatusSum FROM 
		CampaignContact_List map
		INNER JOIN Contact_List list ON list.Id = map.ListId
		INNER JOIN ImportList_Source src ON src.Id = list.SourceId
		INNER JOIN Dealer dealer ON dealer.DealerId = list.DealerId
		WHERE list.IsActive = 1 AND src.IsActive = 1 AND dealer.IsActive = 1 AND map.ListId = @list_id
		AND map.CampaignId=@campaign_id GROUP BY map.Status) t  WHERE  t.Status IN(9,6,12)
	SELECT @Total AS Total
END





GO
/****** Object:  StoredProcedure [dbo].[SP_CreateCallResultTable]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



 CREATE procedure [dbo].[SP_CreateCallResultTable] @campaign_id nvarchar(100)
as begin

 declare @excute_query nvarchar(max);
 set @excute_query='
	 CREATE TABLE Call_Result_Table_'+ @campaign_id +'
	 (
		[RecordId] uniqueidentifier NOT NULL DEFAULT newsequentialid() primary key,
		[ImportList_Id] numeric(20,0) NOT NULL foreign key references Import_List_Table_'+ @campaign_id +'(ImportList_Id),
		[Phone] [nvarchar](20) NOT NULL,
		[PhoneIndex] [int] NOT NULL default(1),
		[CallResult] [int] NOT NULL default(0),
		[CallDateTime] [datetime] NOT NULL default(getutcdate()),
		[WrapupData] [nvarchar](40) NULL,
		[DialerRecoveryKey] [numeric](18, 0) NULL,
		[CreatedOn] [datetime] NOT NULL default getutcdate(),
		[LastUpdatedOn] [datetime] NULL
	); 
	CREATE INDEX IDX_CRT_CR_'+@campaign_id+' on Call_Result_Table_'+@campaign_id+' (CallResult ASC);
	CREATE INDEX IDX_CRT_DRK_'+@campaign_id+' on Call_Result_Table_'+@campaign_id+' (DialerRecoveryKey ASC);
';
exec(@excute_query);

 end






GO
/****** Object:  StoredProcedure [dbo].[SP_CreateImportTable]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_CreateImportTable] @campaign_id nvarchar(100)
as
 begin
 declare @excute_query nvarchar(max);
set @excute_query = 'CREATE TABLE Import_List_Table_'+ @campaign_id +'
    (
	[ImportList_Id] numeric(20,0) NOT NULL IDENTITY primary key,
	[Phone01] [nvarchar](120) NULL,
	[Phone01_Formatted] [nvarchar](120) NULL,
	[Phone02] [nvarchar](120) NULL,
	[Phone02_Formatted] [nvarchar](120) NULL,
	[Phone03] [nvarchar](120) NULL,
	[Phone03_Formatted] [nvarchar](120) NULL,
	[Phone04] [nvarchar](120) NULL,
	[Phone04_Formatted] [nvarchar](120) NULL,
	[Phone05] [nvarchar](120) NULL,
	[Phone05_Formatted] [nvarchar](120) NULL,
	[Phone06] [nvarchar](120) NULL,
	[Phone06_Formatted] [nvarchar](120) NULL,
	[Phone07] [nvarchar](120) NULL,
	[Phone07_Formatted] [nvarchar](120) NULL,
	[Phone08] [nvarchar](120) NULL,
	[Phone08_Formatted] [nvarchar](120) NULL,
	[Phone09] [nvarchar](120) NULL,
	[Phone09_Formatted] [nvarchar](120) NULL,
	[Phone10] [nvarchar](120) NULL,
	[Phone10_Formatted] [nvarchar](120) NULL,
	[FirstName] [nvarchar](255) NULL,
	[LastName] [nvarchar](255) NULL,
	[AccountNumber] [nvarchar](50) NULL,
	[TimeZoneBias] [int] NULL,
	[DstObserved] [bit] NULL,
	[Status] [int] NOT NULL,
	[AttemptId] [int] NULL,
	[MapId] [int] NULL,
	[SkillGroupSkillTargetID] [int] NULL,
	[ExtraData] [xml] NULL,
	[ScheduledDateTime] [datetime] NULL DEFAULT (getutcdate()),
	[PhoneToCallNext] [int] NOT NULL DEFAULT ((1)),
	[CallResult] [int] NOT NULL DEFAULT ((0)),
	[AgentName] [nvarchar](200) NULL,
	[AgentId] [nvarchar](200) NULL,
	[AgentLoginName] [nvarchar](200) NULL,
	[AttemptsMade] [int] NOT NULL DEFAULT ((0)),
	[DialAttempts] [int] NOT NULL DEFAULT ((0)),
	[ImportAttempts] [int] NOT NULL DEFAULT ((0)),
	[FutureUseVarchar1] [nvarchar](255) NULL,
	[FutureUseVarchar2] [nvarchar](255) NULL,
	[FutureUseVarchar3] [nvarchar](255) NULL,
	[FutureUseVarchar4] [nvarchar](255) NULL,
	[FutureUseVarchar5] [nvarchar](255) NULL,
	[FutureUseVarchar6] [nvarchar](255) NULL,
	[FutureUseVarchar7] [nvarchar](255) NULL,
	[FutureUseVarchar8] [nvarchar](255) NULL,
	[FutureUseVarchar9] [nvarchar](255) NULL,
	[FutureUseVarchar10] [nvarchar](255) NULL,
	[FutureUseVarchar11] [nvarchar](255) NULL,
	[FutureUseVarchar12] [nvarchar](255) NULL,
	[FutureUseVarchar13] [nvarchar](255) NULL,
	[FutureUseVarchar14] [nvarchar](255) NULL,
	[FutureUseVarchar15] [nvarchar](255) NULL,
	[FutureUseVarchar16] [nvarchar](255) NULL,
	[ImportDateTime] [datetime] NULL DEFAULT (NULL),
	[ExtraDetails] xml null,
	[CreatedOn] [datetime] NULL DEFAULT (getutcdate()),
	[LastUpdatedOn] [datetime] null
	)';
	exec(@excute_query);
	set @excute_query = 'CREATE INDEX IDX_ILT_SA_'+@campaign_id+ ' ON Import_List_Table_'+@campaign_id+' (AttemptId,Status)';
	exec(@excute_query);
 end







GO
/****** Object:  StoredProcedure [dbo].[SP_Delay_Import]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  PROCEDURE [dbo].[SP_Delay_Import]
@DealerId int,
@search_term nvarchar(max) = null,
@PageNumber  INT ,
@RowsOfPage INT,
@total_records int output
as  
begin
declare @count_query nvarchar(max);
set @count_query = 'with cte as (

SELECT CCL.CampaignList_Id , CED.Name as Campaign_Name , CL.Name as List_Name ,
delay=case when CLI.LastAttemptedOn!=null then (case when -DATEDIFF(MINUTE, getutcdate() , CLI.LastAttemptedOn)>15 then 1 else 0 end) else (case when -DATEDIFF(MINUTE, getutcdate() ,
CLI.PreProcessedOn)>15 then 1 else 0 end )end,
CLI.LastAttemptedOn ,CCL.CreatedOn
from CampaignContact_List CCL
INNER JOIN Contact_List CL ON CCL.ListId=CL.Id
INNER JOIN ContactList_ImportStatus CLI ON CCL.CampaignList_Id=CLI.ListId
INNER JOIN CampaignExtraDetails CED ON CCL.CampaignId=CED.CampaignId

Where CCL.Status IN(1,5,7) 
AND CCL.IsActive=1 AND CL.IsActive=1 AND CED.IsActive=1
AND CL.DealerId= '+CAST(@DealerId AS nvarchar)+' 
AND CCL.CreatedOn between DateADD(Day,DateDIff(Day,0,GetDate()),0) AND GetDate()
 )

select @total_records = count (*)  from cte where delay =1 

';
execute sp_executesql @count_query, N'@total_records int output',@total_records output;
CREATE TABLE #XMLTable (CampaignList_Id int ,attribute varchar(30), operator varchar(30) , value varchar(30) )

INSERT INTO #XMLTable (CampaignList_Id,attribute , operator , value )
SELECT
s.CampaignList_Id,
m.c.value('@attribute', 'varchar(max)') as attribute ,
m.c.value('@operator', 'varchar(max)') as operator,
m.c.value('@value', 'varchar(max)') as value
from CampaignContact_List as s
outer apply s.Filters.nodes('filter/conditions/condition') as m(c);

With DelayTable as (
SELECT CCL.CampaignList_Id , CED.Name as Campaign_Name , CL.Name as List_Name ,TS.value ,
delay=case when CLI.LastAttemptedOn!=null then (case when -DATEDIFF(MINUTE, getutcdate() , CLI.LastAttemptedOn)>15 then 1 else 0 end) else (case when -DATEDIFF(MINUTE, getutcdate() ,
CLI.PreProcessedOn)>15 then 1 else 0 end )end,
CLI.LastAttemptedOn ,CCL.CreatedOn
from CampaignContact_List CCL
INNER JOIN Contact_List CL ON CCL.ListId=CL.Id
INNER JOIN ContactList_ImportStatus CLI ON CCL.CampaignList_Id=CLI.ListId
INNER JOIN CampaignExtraDetails CED ON CCL.CampaignId=CED.CampaignId
INNER JOIN #XMLTable TS ON CCL.CampaignList_Id=TS.CampaignList_Id
Where CCL.Status IN(1,5,7) 
AND CCL.IsActive=1 AND CL.IsActive=1 AND CED.IsActive=1
AND CL.DealerId= @DealerId  AND (@search_term IS NULL OR CED.NAME like '%'+@search_term+'%' )
AND CCL.CreatedOn between DateADD(Day,DateDIff(Day,0,GetDate()),0) AND GetDate()
)
select * from DelayTable where delay =1
ORDER BY CampaignList_Id
OFFSET (@PageNumber-1)*@RowsOfPage ROWS
FETCH NEXT @RowsOfPage ROWS ONLY

DROP TABLE #XMLTable

end




GO
/****** Object:  StoredProcedure [dbo].[Sp_Delete_AgentScript]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[Sp_Delete_AgentScript]@script_id int as begin update AgentScripts set IsActive=0 where AgentScriptID=@script_id end








GO
/****** Object:  StoredProcedure [dbo].[SP_Delete_CustomDNCMaruti]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[SP_Delete_CustomDNCMaruti] @Dnc_Id int AS 
BEGIN
	UPDATE CustomDNCMaruti set IsActive = 0 where DNCId = @Dnc_Id
END











GO
/****** Object:  StoredProcedure [dbo].[SP_Delete_DNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Delete_DNC] @Dnc_Id INT AS 
BEGIN
	UPDATE CustomDNC set IsActive = 0 where DNCId = @Dnc_Id
END
















GO
/****** Object:  StoredProcedure [dbo].[Sp_Delete_EmailConfiguration]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Delete_EmailConfiguration] @config_id int as 
begin
Update EmailConfiguration set  IsActive=0 where  EmailConfigID=@config_id
end













GO
/****** Object:  StoredProcedure [dbo].[Sp_Delete_EmailTemplate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Delete_EmailTemplate]@template_id int as begin update EmailTemplates set IsActive=0 where EmailTemplateID=@template_id end











GO
/****** Object:  StoredProcedure [dbo].[SP_Delete_Global_DNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Delete_Global_DNC] 
	@id uniqueidentifier
as begin
	update Global_DNC set IsActive = 0,LastUpdatedOn = getutcdate() where DNCId = @id
end






GO
/****** Object:  StoredProcedure [dbo].[SP_Delete_GlobalDNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Delete_GlobalDNC] 
	@Dnc_Id uniqueidentifier
as begin
	Delete from GlobalDNC  where DNCId=@Dnc_Id
end







GO
/****** Object:  StoredProcedure [dbo].[SP_Delete_GlobalDNCfromApi]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Delete_GlobalDNCfromApi] 
	@Dnc_RuleId int,
	@phoneNumber nvarchar(50)
as begin
	delete from GlobalDNC where DNCRuleId=@Dnc_RuleId and PhoneNumber=@phoneNumber
end







GO
/****** Object:  StoredProcedure [dbo].[Sp_Delete_MultiContactListData]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[Sp_Delete_MultiContactListData] @status int,@multiListId int
as
begin
delete from MultipleContactListData where MapId=@multiListId
 end












GO
/****** Object:  StoredProcedure [dbo].[SP_Delete_NationalDNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Delete_NationalDNC] 
	@Dnc_Id int
as begin
	update NationalDNC set IsActive=0 where DNCId=@Dnc_Id
end









GO
/****** Object:  StoredProcedure [dbo].[Sp_Delete_SMSConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[Sp_Delete_SMSConfig]@config_id int as begin update SMSConfiguration set IsActive=0 where SMSConfigId=@config_id end











GO
/****** Object:  StoredProcedure [dbo].[Sp_Delete_SMSTemplate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[Sp_Delete_SMSTemplate]@template_id int as begin update SMSTemplates set IsActive=0 where SMSTemplateID=@template_id end











GO
/****** Object:  StoredProcedure [dbo].[SP_Delete_Tenant]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Delete_Tenant] @TenantId INT AS 
BEGIN
	UPDATE Tenants set IsActive = 0 WHERE Id = @TenantId
END

















GO
/****** Object:  StoredProcedure [dbo].[SP_Delete_User]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Delete_User] @user_id INT AS 
BEGIN
	UPDATE UserMaster set IsActive = 0 WHERE UserId = @user_id
END
















GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteAllList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SP_DeleteAllList]  
@CampaignId int
AS
BEGIN
    BEGIN TRAN
	      
        update CampaignContact_List set IsActive=0 where CampaignId=@CampaignId 

		 IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END

update ContactMapGroup set IsActive=0 where CampaignId=@CampaignId 

 IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END


update Contact_List set IsActive=0 where Id in  (select CL.Id from Contact_List CL inner join CampaignContact_List CCL ON CL.Id=CCL.ListId where CCL.CampaignId=@CampaignId)


 IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END


        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END

     

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
END





GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteAllList12]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SP_DeleteAllList12]
@CampaignId int
AS
BEGIN
    BEGIN TRAN
	      
        update CampaignContactList set IsActive=0 where CampaignId=@CampaignId 
update ContactMapGroup set IsActive=0 where CampaignId=@CampaignId 
update Contact_List set IsActive=0 where Id in  (select CL.Id from Contact_List CL inner join CampaignContact_List CCL ON CL.Id=CCL.ListId where CCL.CampaignId=@CampaignId)


        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END

     

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
END





GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteCallback]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[SP_DeleteCallback]
@id int, @status int, @lastUpdatedOn datetime
as
begin
update CallbackMaster set IsDeleted=1, Status=@status,LastUpdatedOn= @lastUpdatedOn where Id=@id
end


GO
/****** Object:  StoredProcedure [dbo].[Sp_DeleteCampaignContact_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_DeleteCampaignContact_List] @id int as begin
	Update CampaignContact_List set  IsActive=0, LastUpdatedOn = getdate() WHERE CampaignList_Id = @id
 end















GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteCampaignHoliday]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteCampaignHoliday] @tenant_id int, @map_id int as 
begin
	delete from CampaignHoliday where TenantId = @tenant_id and Id = @map_id;
end











GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteCampaignRecords]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[SP_DeleteCampaignRecords] @campaign_id int,@tenant_id int,@status int  as  begin
	if(dbo.TenantState(@tenant_id)=1)
	begin
	declare @table_name nvarchar(100);
	set @table_name = 'PreviewCampaignImportList';
	declare @sql nvarchar(max);
	set @sql = 'update '+@table_name+' set Status = '+cast(@status as nvarchar)+' where CampaignId = '+cast(@campaign_id as nvarchar);
	execute sp_executesql @sql;
	end
end











GO
/****** Object:  StoredProcedure [dbo].[Sp_DeleteContact_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_DeleteContact_List] @id int as begin
	Update Contact_List set  IsActive=0, LastUpdatedOn = getutcdate() WHERE Id = @id
 end














GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteContactMapGroupIterationById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_DeleteContactMapGroupIterationById] @Id int

as begin

Delete from ContactMapGroupIteration where Id=@Id
end






GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteDealer] 
	@id int
as begin
Update Dealer set IsActive=0 where DealerId=@id;
--Update [DealerExtraDetails] set IsActive=0 where DealerId=@id;
Delete from DealerExtraDetails where DealerId=@id;
end








GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteDealerStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteDealerStatus] 
	@id int
as begin
Update Dealer set Status=11 where DealerId=@id;
end







GO
/****** Object:  StoredProcedure [dbo].[sp_deleteDuplicateData]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_deleteDuplicateData]
as begin

-- Function    : sp_deleteDuplicateData
--
-- Description : Function to delete duplicate Data
--
-- Version     : 1.0.1
--
-- Author      : consilium software inc,
--
--
-- Change Information.
-- -------------------------------
-- 
-- Who                    Date                Reason.
-- ------------------------------------------------------------------------------------------------------------------
-- Shubham Singh          21-Oct-2019	      Created.
---------------------------------------------------------------------------------------------------------------------
	set nocount on;
	select distinct  CampaignList_Id, CampaignId into #CLTemp from CampaignContact_List 
		   where ListId in (select Distinct Id  from Contact_List where IsActive = 0)
	
	declare @CampaignId nvarchar(max) 
	declare @count int
    declare @sql nvarchar(max)
	
	select @count = (select count(distinct CampaignId) from #CLTemp)
	
	while @count>0 
	begin
		select @CampaignId = (select distinct top 1 CampaignId from #CLTemp)
		
		set @sql='
		alter table Call_Result_Table_'+@CampaignId+' 
		ADD CONSTRAINT fk_CRT_ImportList_ID'+@CampaignId+'
		FOREIGN KEY (ImportList_Id)
		REFERENCES Import_List_Table_'+@CampaignId+'(ImportList_Id)
		ON DELETE CASCADE;
		
		delete from Import_List_Table_'+@CampaignId+' 
		where MapID in (select CampaignList_Id from #CLTemp where CampaignId = '+ @CampaignId+');
		
		alter table Call_Result_Table_'+@CampaignId+' 
		drop constraint fk_CRT_ImportList_ID'+@CampaignId+''		

		execute sp_executesql @sql;
		delete from #CLTemp where CampaignId = @CampaignId;
		set @count =@count-1
	end
	
	drop table #CLTemp;
	
	set nocount off;
end





GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteEmailCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_DeleteEmailCampaign] @email_campaign_id int as begin
update EmailCampaign set IsActive=0 where EmailCampaignId=@email_campaign_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteGroup]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteGroup] 
	
	@group_id int
	
as begin
	Delete GroupMaster  where  Id = @group_id
end


GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteHoliday]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteHoliday] @holiday_id int as begin
	update Holiday set IsActive = 0, LastUpdatedOn = GETUTCDATE() where HolidayId = @holiday_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteHolidaybyDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteHolidaybyDealer] @Dealer_id int as begin
	Delete from Holiday where DealerId=@Dealer_id
end











GO
/****** Object:  StoredProcedure [dbo].[Sp_DeleteImportList_Source]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_DeleteImportList_Source] @id int as begin
	Update ImportList_Source set  IsActive=0, LastUpdatedOn = getdate() WHERE Id = @id
 end















GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteListByCampaignIdAndListId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SP_DeleteListByCampaignIdAndListId]  
@CampaignId int,
@ListIds nvarchar(max)
AS
BEGIN
    BEGIN TRAN
        EXECUTE(N'update CampaignContact_List set IsActive=0 where CampaignId='+@CampaignId+' and ListId IN ('+@ListIds+')')

		 IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END

		EXECUTE(N'update ContactMapGroup set IsActive=0 where CampaignId= '+@CampaignId+' and ListId IN ('+@ListIds+')')

 IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END

		Execute (N'update Contact_List set IsActive=0 where Id IN ('+@ListIds+')')

 IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END

        IF @@ERROR <> 0
        BEGIN
            ROLLBACK TRAN
            RAISERROR ('Error occured  ', 16, 1)
            RETURN -1
        END

    IF @@TRANCOUNT > 0
    BEGIN
        COMMIT TRAN
        RETURN 0
    END
END




GO
/****** Object:  StoredProcedure [dbo].[SP_DeletePreviewCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[SP_DeletePreviewCampaign] @campaign_id int,@status int as begin
	update PreviewCampaign set IsActive = 0 where PreviewCampaignId = @campaign_id;
	update PreviewCampaign set NoOfSkill = 0 where PreviewCampaignId = @campaign_id;
	update PreviewCampaignImportList set Status=@status where CampaignId = @campaign_id;
	delete from SkillGroupMap where PreviewCampaignId=@campaign_id;
	delete from PreviewCampaignContact_List where CampaignId = @campaign_id;
end









GO
/****** Object:  StoredProcedure [dbo].[SP_DeletePreviewCampaignSkillMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[SP_DeletePreviewCampaignSkillMap] @campaign_id int as begin
	delete from SkillGroupMap where PreviewCampaignId=@campaign_id
end







GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteRechurnPolicy]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteRechurnPolicy]  @id int as 
begin
	update RechurnPolicy set IsActive=0 where Id= @id;
end





GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteRechurnPolicyMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteRechurnPolicyMap]  @id int as 
begin
	update RechurnPolicyMap set IsActive=0 where Id= @id;
end






GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteRole]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteRole] @role_Id int
as begin
update Role_Master set IsActive=0 where RoleId=@role_Id
 end









GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteSMSCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteSMSCampaign] @campaign_id int as begin
	update SMSCampaign set IsActive = 0 where SMSCampaignId = @campaign_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteUserMaster]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_DeleteUserMaster] @usermaster_Id int
as begin
update User_Master set IsActive=0 where UserId=@usermaster_Id
 end









GO
/****** Object:  StoredProcedure [dbo].[SP_DeleteWraupReasonCode]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DeleteWraupReasonCode] @wrapupcode_Id int,@dealer_Id int
as 
begin 
update PreviewWarpReasonCode set IsActive=0 where WrapupCodeId=@wrapupcode_Id and DealerId=@dealer_Id
end










GO
/****** Object:  StoredProcedure [dbo].[SP_Dialer_Result]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Dialer_Result] 
--@startdatetime datetime='',
--@enddatetime datetime='',
--@campaignId nvarchar(max)  
as
  Declare @var1 nvarchar(max);
  Declare @varCampaignId nvarchar(max);
 Declare @var2 nvarchar(max);
  set nocount on;
  begin
  

  CREATE TABLE #Call_Result_Table(
	[RecordId] [uniqueidentifier] NOT NULL,
	[ImportList_Id] [numeric](20, 0) NOT NULL,
	[Phone] [nvarchar](20) NOT NULL,
	[PhoneIndex] [int] NOT NULL,
	[CallResult] [int] NOT NULL,
	[CallDateTime] [datetime] NOT NULL,
	[WrapupData] [nvarchar](40) NULL,
	[DialerRecoveryKey] [numeric](18, 0) NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL
	);

	CREATE TABLE #Import_List_Table(
	[ImportList_Id] [numeric](20, 0) NULL,
	[Phone01] [nvarchar](120) NULL,
	[Phone01_Formatted] [nvarchar](120) NULL,
	[Phone02] [nvarchar](120) NULL,
	[Phone02_Formatted] [nvarchar](120) NULL,
	[Phone03] [nvarchar](120) NULL,
	[Phone03_Formatted] [nvarchar](120) NULL,
	[Phone04] [nvarchar](120) NULL,
	[Phone04_Formatted] [nvarchar](120) NULL,
	[Phone05] [nvarchar](120) NULL,
	[Phone05_Formatted] [nvarchar](120) NULL,
	[Phone06] [nvarchar](120) NULL,
	[Phone06_Formatted] [nvarchar](120) NULL,
	[Phone07] [nvarchar](120) NULL,
	[Phone07_Formatted] [nvarchar](120) NULL,
	[Phone08] [nvarchar](120) NULL,
	[Phone08_Formatted] [nvarchar](120) NULL,
	[Phone09] [nvarchar](120) NULL,
	[Phone09_Formatted] [nvarchar](120) NULL,
	[Phone10] [nvarchar](120) NULL,
	[Phone10_Formatted] [nvarchar](120) NULL,
	[FirstName] [nvarchar](255) NULL,
	[LastName] [nvarchar](255) NULL,
	[AccountNumber] [nvarchar](50) NULL,
	[TimeZoneBias] [int] NULL,
	[DstObserved] [bit] NULL,
	[Status] [int] NOT NULL,
	[AttemptId] [int] NULL,
	[MapId] [int] NULL,
	[SkillGroupSkillTargetID] [int] NULL,	
	[ScheduledDateTime] [datetime] NULL,
	[PhoneToCallNext] [int] NOT NULL,
	[CallResult] [int] NOT NULL,
	[AgentName] [nvarchar](200) NULL,
	[AgentId] [nvarchar](200) NULL,
	[AgentLoginName] [nvarchar](200) NULL,
	[AttemptsMade] [int] NOT NULL,
	[DialAttempts] [int] NOT NULL,
	[ImportAttempts] [int] NOT NULL,
	[FutureUseVarchar1] [nvarchar](255) NULL,
	[FutureUseVarchar2] [nvarchar](255) NULL,
	[FutureUseVarchar3] [nvarchar](255) NULL,
	[FutureUseVarchar4] [nvarchar](255) NULL,
	[FutureUseVarchar5] [nvarchar](255) NULL,
	[FutureUseVarchar6] [nvarchar](255) NULL,
	[FutureUseVarchar7] [nvarchar](255) NULL,
	[FutureUseVarchar8] [nvarchar](255) NULL,
	[FutureUseVarchar9] [nvarchar](255) NULL,
	[FutureUseVarchar10] [nvarchar](255) NULL,
	[FutureUseVarchar11] [nvarchar](255) NULL,
	[FutureUseVarchar12] [nvarchar](255) NULL,
	[FutureUseVarchar13] [nvarchar](255) NULL,
	[FutureUseVarchar14] [nvarchar](255) NULL,
	[FutureUseVarchar15] [nvarchar](255) NULL,
	[ImportDateTime] [datetime] NULL,	
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[FutureUseVarchar16] [nvarchar](255) NULL
	);

    create table #campaign(CampaignID int);

	--insert into #campaign
	--select Value from dbo.Split_demo(@campaignId);
	
   declare cursor_updated  cursor
   for 
   select ocd.CampaignID from CampaignExtraDetails ocd(nolock)
   open cursor_updated

   fetch next from cursor_updated into @varCampaignId
   while @@FETCH_STATUS = 0 

   begin 

	 
	  set @var1='insert into #Call_Result_Table select * from 
	  Call_Result_Table_'+ @varCampaignId +'';

	  execute(@var1);
	    set @var2='insert into #Import_List_Table select [ImportList_Id]
      ,[Phone01]
      ,[Phone01_Formatted]
      ,[Phone02]
      ,[Phone02_Formatted]
      ,[Phone03]
      ,[Phone03_Formatted]
      ,[Phone04]
      ,[Phone04_Formatted]
      ,[Phone05]
      ,[Phone05_Formatted]
      ,[Phone06]
      ,[Phone06_Formatted]
      ,[Phone07]
      ,[Phone07_Formatted]
      ,[Phone08]
      ,[Phone08_Formatted]
      ,[Phone09]
      ,[Phone09_Formatted]
      ,[Phone10]
      ,[Phone10_Formatted]
      ,[FirstName]
      ,[LastName]
      ,[AccountNumber]
      ,[TimeZoneBias]
      ,[DstObserved]
      ,[Status]
      ,[AttemptId]
      ,[MapId]
      ,[SkillGroupSkillTargetID]     
      ,[ScheduledDateTime]
      ,[PhoneToCallNext]
      ,[CallResult]
      ,[AgentName]
      ,[AgentId]
      ,[AgentLoginName]
      ,[AttemptsMade]
      ,[DialAttempts]
      ,[ImportAttempts]
      ,[FutureUseVarchar1]
      ,[FutureUseVarchar2]
      ,[FutureUseVarchar3]
      ,[FutureUseVarchar4]
      ,[FutureUseVarchar5]
      ,[FutureUseVarchar6]
      ,[FutureUseVarchar7]
      ,[FutureUseVarchar8]
      ,[FutureUseVarchar9]
      ,[FutureUseVarchar10]
      ,[FutureUseVarchar11]
      ,[FutureUseVarchar12]
      ,[FutureUseVarchar13]
      ,[FutureUseVarchar14]
      ,[FutureUseVarchar15]
      ,[ImportDateTime]
      ,[CreatedOn]
      ,[LastUpdatedOn]
      ,[FutureUseVarchar16] from 
	  Import_List_Table_'+ @varCampaignId +' where  convert(varchar(10),CreatedOn,120)=convert(varchar(10),GETDATE(),120) ';

	  execute(@var2);
		  
    

	 



   fetch next from cursor_updated into @varCampaignId

   end
   CLOSE cursor_updated  

DEALLOCATE cursor_updated 



     select distinct ocd.Id as contactAttemptId,ocd.AccountNumber as contactId,
	 ILT.[FutureUseVarchar16] as externalContactId,
	 cast(ILT.DialAttempts as int) as attemptNum,
	 Convert(varchar(19),ocd.DateTime,120) as CallDateTime,
	 'Phone' as contactMethod,
   ocd.Phone as contactEndpoint,
   --case  dd.CallStatusZone1 when 'A' then 'Active'
   --when 'B' then 'CallBack Requested'
   --when 'C' then 'Record Closed'
   --when 'D' then 'Dialed'
   --when 'F' then 'Fax Machine'
   --when 'L' then 'Not Allocated'
   --when 'J' then 'Agent Rejected' 
   --when 'M' then 'Max Attempt Reached'
   --when 'P' then 'Pending'
   --when 'R' then 'Retry'
   --when 'S' then 'Scheduled CallBack Requested'
   --when 'U' then 'Unknown'
   --when 'X' then 'Agent Not Available'
   --end as attemptState,
   case  dd.CallResult when 0 then 'CALL_QUEUED' when 2 then 'CALL_CENTER_FAILURE'
   when 3 then 'UNREACHABLE'
   when 4 then 'TEMP_TELCO_FAILURE'
   when 5 then 'TEMP_TELCO_FAILURE'
   when 6 then 'TEMP_TELCO_FAILURE'
   when 7 then 'BAD_NUMBER'
   when 8 then 'RING_NO_ANSWER' 
   when 9 then 'BUSY'
   when 10 then 'CONNECTED_TO_AGENT'
   when 11 then 'MODEM'
   when 12 then 'ANSWERING_MACHINE'
   when 13 then 'UNREACHABLE'
   when 14 then 'AGENT_CALLED'
   when 15 then 'AGENT_ANSWERING_MACHINE'
   when 16 then 'CALL_CENTER_FAILURE?'
   when 17 then 'TEMP_TELCO_FAILURE'
   when 18 then 'AGENT_REJECTED'
   when 19 then 'AGENT_REJECTED'
   when 20 then 'MESSAGE_PLAYED' 
   when 21 then 'IMMEDIATE_HANG_UP'
   when 22 then 'TEMP_TELCO_FAILURE'
   when 23 then 'AGENT_BAD_NUMBER'
   when 24 then 'CONNECTED_TO_AGENT'
   when 25 then 'CALL_CENTER_FAILURE?'
   when 26 then 'DNC' 
   when 27 then 'RING_NO_ANSWER'
   when 28 then 'IMMEDIATE_HANG_UP'
   when 29 then 'TEMP_TELCO_FAILURE'
   when 30 then 'TEMP_TELCO_FAILURE' 
   when 31 then 'TEMP_TELCO_FAILURE'
   when 32 then 'CALL_CENTER_FAILURE'
   when 33 then 'AGENT_REJECTED'   
   end as attemptState,
   --case ocd.Status when 1 then 'Pending' 
   --when 2 then 'Active' 
   --when 3 then 'Duplicate' 
   --when 4 then 'Invalid' 
   --when 5 then 'Valid' 
   --when 6 then 'Excluded'
   --when 7 then 'Retry' 
   --when 8 then 'Processing' 
   --when 9 then 'Imported'
   --when 10 then 'Failed' 
   --when 11 then 'Deleted' 
   --when 12 then 'Completed' 
   --when 13 then 'Expired'
   --when 14 then 'InActive' 
   --when 15 then 'SkippedOrRejected' 
   --when 16 then 'NotFoundCallResult'
   --when 17 then 'Schedule' 
   --when 18 then 'DailerAutoRetry'
   --when 20 then 'GlobalDuplicate' end as contactState,
  case 
    when dd.CallResult=21 then 'ABANDONED'
   when dd.CallResult=26 then 'DNC'
   when dd.CallResult=7 then 'INVALID'
  when dd.CallStatusZone1='A' then 'READY'
   when dd.CallStatusZone1='B' then 'RETRY_SCHEDULED'
   when dd.CallStatusZone1='C' then 'COMPLETE'
   when dd.CallStatusZone1='D' then 'COMPLETE'
   when dd.CallStatusZone1='F' then 'MODEM'
   when dd.CallStatusZone1='L' then 'INVALID'
   when dd.CallStatusZone1='J' then 'COMPLETE' 
   when dd.CallStatusZone1='M' then 'MAX_ATTEMPTS_REACHED'
   when dd.CallStatusZone1='P' then 'READY'
   when dd.CallStatusZone1='R' then 'RETRY_SCHEDULED'
   when dd.CallStatusZone1='S' then 'RETRY_SCHEDULED'
   when dd.CallStatusZone1='U' then 'INVALID'
   when dd.CallStatusZone1='X' then 'INVALID' 
 
   end  as contactState,
  
    case dd.CallResult 
   when 10 then 'HUMAN' 
   when 11 then 'MODEM'
   when 12 then 'ANSWERING_MACHINE'
   when 28 then 'SILENCE' else 'NO_CPA_USED'
       end  as cpaResult,
   ILT.AgentLoginName as answeringAgent,
   dd.CallResult as contactDisposition,
   ILT.FutureUseVarchar1,ILT.FutureUseVarchar2,ILT.FutureUseVarchar3,ILT.FutureUseVarchar4,
   ILT.FutureUseVarchar5,ILT.FutureUseVarchar6,ILT.FutureUseVarchar7,ILT.FutureUseVarchar8,ILT.FutureUseVarchar9,
   ILT.FutureUseVarchar10,ILT.FutureUseVarchar11,ILT.FutureUseVarchar12,ILT.FutureUseVarchar13,ILT.FutureUseVarchar14,ILT.FutureUseVarchar15,
   cast(ocd.CampaignID as int)as CampaignID,   CED.Name
	 from Outbound_Call_Detail_1000 ocd(nolock)
	  --left join CampaignContact_List ccl on ocd.CampaignID=ccl.CampaignId 
   --left join ContactList_ImportStatus clis on ccl.CampaignList_Id=clis.ListId 
   --left join #Call_Result_Table CRT on ocd.AccountNumber=CRT.ImportList_Id 
   inner join #Import_List_Table ILT on ocd.AccountNumber=ILT.ImportList_Id 
   inner join CampaignExtraDetails CED on ocd.CampaignID=CED.CampaignId 
   inner join [192.168.1.34].[ins11_awdb].[dbo].[Dialer_Detail] dd on  ocd.RecoveryKey=dd.RecoveryKey
   

 where convert(varchar(10),ocd.DateTime,120)=convert(varchar(10),GETDATE(),120) ---between Cast(GETDATE() as date) and GETDATE() --and  ILT.CreatedOn between Cast(GETDATE() as date) and GETDATE() 
  end

---  select * from [DAYPRDUCCSLMDBA].[pcce_awdb].[dbo].[Dialer_Detail] dd where DateTime between Cast(GETDATE()-1 as date) and GETDATE()
GO
/****** Object:  StoredProcedure [dbo].[SP_Dialer_Result_report_Campaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create procedure [dbo].[SP_Dialer_Result_report_Campaign] --'6836'
@campaignId nvarchar(max)  
as
  Declare @var1 nvarchar(max);
  Declare @varCampaignId nvarchar(max);
 Declare @var2 nvarchar(max);
  set nocount on;
  begin
  

  CREATE TABLE #Call_Result_Table(
	[RecordId] [uniqueidentifier] NOT NULL,
	[ImportList_Id] [numeric](20, 0) NOT NULL,
	[Phone] [nvarchar](20) NOT NULL,
	[PhoneIndex] [int] NOT NULL,
	[CallResult] [int] NOT NULL,
	[CallDateTime] [datetime] NOT NULL,
	[WrapupData] [nvarchar](40) NULL,
	[DialerRecoveryKey] [numeric](18, 0) NULL,
	[CreatedOn] [datetime] NOT NULL,
	[LastUpdatedOn] [datetime] NULL
	);

	CREATE TABLE #Import_List_Table(
	[ImportList_Id] [numeric](20, 0) NOT NULL,
	[Phone01] [nvarchar](120) NULL,
	[Phone01_Formatted] [nvarchar](120) NULL,
	[Phone02] [nvarchar](120) NULL,
	[Phone02_Formatted] [nvarchar](120) NULL,
	[Phone03] [nvarchar](120) NULL,
	[Phone03_Formatted] [nvarchar](120) NULL,
	[Phone04] [nvarchar](120) NULL,
	[Phone04_Formatted] [nvarchar](120) NULL,
	[Phone05] [nvarchar](120) NULL,
	[Phone05_Formatted] [nvarchar](120) NULL,
	[Phone06] [nvarchar](120) NULL,
	[Phone06_Formatted] [nvarchar](120) NULL,
	[Phone07] [nvarchar](120) NULL,
	[Phone07_Formatted] [nvarchar](120) NULL,
	[Phone08] [nvarchar](120) NULL,
	[Phone08_Formatted] [nvarchar](120) NULL,
	[Phone09] [nvarchar](120) NULL,
	[Phone09_Formatted] [nvarchar](120) NULL,
	[Phone10] [nvarchar](120) NULL,
	[Phone10_Formatted] [nvarchar](120) NULL,
	[FirstName] [nvarchar](255) NULL,
	[LastName] [nvarchar](255) NULL,
	[AccountNumber] [nvarchar](50) NULL,
	[TimeZoneBias] [int] NULL,
	[DstObserved] [bit] NULL,
	[Status] [int] NOT NULL,
	[AttemptId] [int] NULL,
	[MapId] [int] NULL,
	[SkillGroupSkillTargetID] [int] NULL,
	[ScheduledDateTime] [datetime] NULL,
	[PhoneToCallNext] [int] NOT NULL,
	[CallResult] [int] NOT NULL,
	[AgentName] [nvarchar](200) NULL,
	[AgentId] [nvarchar](200) NULL,
	[AgentLoginName] [nvarchar](200) NULL,
	[AttemptsMade] [int] NOT NULL,
	[DialAttempts] [int] NOT NULL,
	[ImportAttempts] [int] NOT NULL,
	[FutureUseVarchar1] [nvarchar](255) NULL,
	[FutureUseVarchar2] [nvarchar](255) NULL,
	[FutureUseVarchar3] [nvarchar](255) NULL,
	[FutureUseVarchar4] [nvarchar](255) NULL,
	[FutureUseVarchar5] [nvarchar](255) NULL,
	[FutureUseVarchar6] [nvarchar](255) NULL,
	[FutureUseVarchar7] [nvarchar](255) NULL,
	[FutureUseVarchar8] [nvarchar](255) NULL,
	[FutureUseVarchar9] [nvarchar](255) NULL,
	[FutureUseVarchar10] [nvarchar](255) NULL,
	[FutureUseVarchar11] [nvarchar](255) NULL,
	[FutureUseVarchar12] [nvarchar](255) NULL,
	[FutureUseVarchar13] [nvarchar](255) NULL,
	[FutureUseVarchar14] [nvarchar](255) NULL,
	[FutureUseVarchar15] [nvarchar](255) NULL,
	[ImportDateTime] [datetime] NULL,
	[CreatedOn] [datetime] NULL,
	[LastUpdatedOn] [datetime] NULL,
	[FutureUseVarchar16] [nvarchar](255) NULL
	);

    create table #campaign(CampaignID int);

	insert into #campaign
	select Value from dbo.Split_demo(@campaignId);
	
   declare cursor_updated  cursor
   for 
   select CampaignID from #campaign ocd(nolock)
   open cursor_updated

   fetch next from cursor_updated into @varCampaignId
   while @@FETCH_STATUS = 0 

   begin 

	 
	  set @var1='insert into #Call_Result_Table select * from 
	  Call_Result_Table_'+ @varCampaignId +'';

	  execute(@var1);
	    set @var2='insert into #Import_List_Table select [ImportList_Id]
      ,[Phone01]
      ,[Phone01_Formatted]
      ,[Phone02]
      ,[Phone02_Formatted]
      ,[Phone03]
      ,[Phone03_Formatted]
      ,[Phone04]
      ,[Phone04_Formatted]
      ,[Phone05]
      ,[Phone05_Formatted]
      ,[Phone06]
      ,[Phone06_Formatted]
      ,[Phone07]
      ,[Phone07_Formatted]
      ,[Phone08]
      ,[Phone08_Formatted]
      ,[Phone09]
      ,[Phone09_Formatted]
      ,[Phone10]
      ,[Phone10_Formatted]
      ,[FirstName]
      ,[LastName]
      ,[AccountNumber]
      ,[TimeZoneBias]
      ,[DstObserved]
      ,[Status]
      ,[AttemptId]
      ,[MapId]
      ,[SkillGroupSkillTargetID]     
      ,[ScheduledDateTime]
      ,[PhoneToCallNext]
      ,[CallResult]
      ,[AgentName]
      ,[AgentId]
      ,[AgentLoginName]
      ,[AttemptsMade]
      ,[DialAttempts]
      ,[ImportAttempts]
      ,[FutureUseVarchar1]
      ,[FutureUseVarchar2]
      ,[FutureUseVarchar3]
      ,[FutureUseVarchar4]
      ,[FutureUseVarchar5]
      ,[FutureUseVarchar6]
      ,[FutureUseVarchar7]
      ,[FutureUseVarchar8]
      ,[FutureUseVarchar9]
      ,[FutureUseVarchar10]
      ,[FutureUseVarchar11]
      ,[FutureUseVarchar12]
      ,[FutureUseVarchar13]
      ,[FutureUseVarchar14]
      ,[FutureUseVarchar15]
      ,[ImportDateTime]
      ,[CreatedOn]
      ,[LastUpdatedOn]
      ,[FutureUseVarchar16] from 
	  Import_List_Table_'+ @varCampaignId +' where Convert(varchar(10),CreatedOn,120)=Convert(varchar(10),Getdate(),120)';

	  execute(@var2);
		  
    

	 



   fetch next from cursor_updated into @varCampaignId

   end
   CLOSE cursor_updated  

DEALLOCATE cursor_updated 



     select distinct ocd.Id as contactAttemptId,ocd.AccountNumber as contactId,
	  ILT.[FutureUseVarchar16] as externalContactId,
	 cast(ILT.DialAttempts as int) as attemptNum,
	 Convert(varchar(19),ocd.DateTime,120) as CallDateTime,
	 'Phone' as contactMethod,
	 ocd.Phone as contactEndpoint,
   case  dd.CallResult when 0 then 'CALL_QUEUED' when 2 then 'CALL_CENTER_FAILURE'
   when 3 then 'UNREACHABLE'
   when 4 then 'TEMP_TELCO_FAILURE'
   when 5 then 'TEMP_TELCO_FAILURE'
   when 6 then 'TEMP_TELCO_FAILURE'
   when 7 then 'BAD_NUMBER'
   when 8 then 'RING_NO_ANSWER' 
   when 9 then 'BUSY'
   when 10 then 'CONNECTED_TO_AGENT'
   when 11 then 'MODEM'
   when 12 then 'ANSWERING_MACHINE'
   when 13 then 'UNREACHABLE'
   when 14 then 'AGENT_CALLED'
   when 15 then 'AGENT_ANSWERING_MACHINE'
   when 16 then 'CALL_CENTER_FAILURE?'
   when 17 then 'TEMP_TELCO_FAILURE'
   when 18 then 'AGENT_REJECTED'
   when 19 then 'AGENT_REJECTED'
   when 20 then 'MESSAGE_PLAYED' 
   when 21 then 'IMMEDIATE_HANG_UP'
   when 22 then 'TEMP_TELCO_FAILURE'
   when 23 then 'AGENT_BAD_NUMBER'
   when 24 then 'CONNECTED_TO_AGENT'
   when 25 then 'CALL_CENTER_FAILURE?'
   when 26 then 'DNC' 
   when 27 then 'RING_NO_ANSWER'
   when 28 then 'IMMEDIATE_HANG_UP'
   when 29 then 'TEMP_TELCO_FAILURE'
   when 30 then 'TEMP_TELCO_FAILURE' 
   when 31 then 'TEMP_TELCO_FAILURE'
   when 32 then 'CALL_CENTER_FAILURE'
   when 33 then 'AGENT_REJECTED'   
   end as attemptState,
   case 
   when dd.CallResult=21 then 'ABANDONED'
   when dd.CallResult=26 then 'DNC'
   when dd.CallResult=7 then 'INVALID'
   when dd.CallStatusZone1='A' then 'READY'
   when dd.CallStatusZone1='B' then 'RETRY_SCHEDULED'
   when dd.CallStatusZone1='C' then 'COMPLETE'
   when dd.CallStatusZone1='D' then 'COMPLETE'
   when dd.CallStatusZone1='F' then 'MODEM'
   when dd.CallStatusZone1='L' then 'INVALID'
   when dd.CallStatusZone1='J' then 'COMPLETE' 
   when dd.CallStatusZone1='M' then 'MAX_ATTEMPTS_REACHED'
   when dd.CallStatusZone1='P' then 'READY'
   when dd.CallStatusZone1='R' then 'RETRY_SCHEDULED'
   when dd.CallStatusZone1='S' then 'RETRY_SCHEDULED'
   when dd.CallStatusZone1='U' then 'INVALID'
   when dd.CallStatusZone1='X' then 'INVALID' 
   end as contactState,
   case dd.CallResult 
   when 10 then 'HUMAN' 
   when 11 then 'MODEM'
   when 12 then 'ANSWERING_MACHINE'
   when 28 then 'SILENCE' else 'NO_CPA_USED'
       end as cpaResult,
   ILT.AgentLoginName as answeringAgent,
   dd.CallResult as contactDisposition,
   ILT.FutureUseVarchar1 as dataVar1,ILT.FutureUseVarchar2 as dataVar2,ILT.FutureUseVarchar3 as dataVar3,ILT.FutureUseVarchar4 as dataVar4,
   ILT.FutureUseVarchar5 as dataVar5,ILT.FutureUseVarchar6 as dataVar6,ILT.FutureUseVarchar7 as dataVar7,ILT.FutureUseVarchar8 as dataVar8,ILT.FutureUseVarchar9 as dataVar9,
   ILT.FutureUseVarchar10 as dataVar10,ILT.FutureUseVarchar11 as dataVar11,ILT.FutureUseVarchar12 as dataVar12,ILT.FutureUseVarchar13 as dataVar13,ILT.FutureUseVarchar14 as dataVar14,ILT.FutureUseVarchar15 as dataVar15,
   cast(ocd.CampaignID as int)as CampaignID
	 from Outbound_Call_Detail_1000 ocd(nolock)
	  --left join CampaignContact_List ccl on ocd.CampaignID=ccl.CampaignId 
   --left join ContactList_ImportStatus clis on ccl.CampaignList_Id=clis.ListId 
   --left join #Call_Result_Table CRT on ocd.AccountNumber=CRT.ImportList_Id 
   inner join #Import_List_Table ILT on ocd.AccountNumber=ILT.ImportList_Id 
   inner join CampaignExtraDetails CED on ocd.CampaignID=CED.CampaignId 
   inner join [192.168.1.34].[ins11_awdb].[dbo].[Dialer_Detail] dd on  ocd.RecoveryKey=dd.RecoveryKey
   

 where Convert(varchar(10),ocd.DateTime,120)=Convert(varchar(10),Getdate(),120) --and  ILT.CreatedOn between @startdatetime and @enddatetime 
 and CED.CampaignId in(select CampaignID from #campaign)
  end
GO
/****** Object:  StoredProcedure [dbo].[SP_DisableAllCampaigns]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_DisableAllCampaigns] @tenant_id int as 
begin
	update CampaignState set State = 0 where TenantId = @tenant_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_Get_ActiveDNCByCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_ActiveDNCByCampaign] @campaign_id int, @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*)
 FROM CustomDNCMaruti';
		set @where_clause = ' WHERE IsActive = 1 AND TenantId = '+cast(@tenant_id as varchar) ;
		
		set @where_clause =  @where_clause+'AND (CampaignId='+cast(@campaign_id as varchar )+' OR CampaignId < 1)';
		
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId'))  
		begin
			set @where_clause = @where_clause +' AND ('+@filter_col + ' = '+cast(@filter_by as varchar)+' OR CampaignId < 1)';
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND  contains (PhoneNumber , '' '+ @search_term+''' )';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCId DESC) AS RowNumber , *  FROM CustomDNCMaruti ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	else
		set @total_records = 0
END





GO
/****** Object:  StoredProcedure [dbo].[SP_Get_ActiveNationalDNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_ActiveNationalDNC] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM NationalDNC';
		set @where_clause = ' WHERE IsActive = 1 AND TenantId = '+cast(@tenant_id as varchar) ;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CreatedOn'))  
		begin
			set @where_clause = @where_clause +' AND ('+@filter_col + ' = '+cast(@filter_by as varchar);
		end
	
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND PhoneNumber like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCId DESC) AS RowNumber ,*  FROM NationalDNC ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	else
		set @total_records = 0
END








GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Agent_Scripts]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create  procedure [dbo].[SP_Get_Agent_Scripts] @tenant_id int,@page_no int, @records_per_page int, @total_records int output ,@dealer_id int
as begin
if(dbo.TenantState(@tenant_id) = 1)
	begin
select @total_records = COUNT(*) FROM AgentScripts where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id;
	WITH All_AgentScripts AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY AgentScriptID ASC) AS RowNumber , *  FROM  AgentScripts where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id
	) SELECT * FROM All_AgentScripts WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
	end
	else
		set @total_records = 0
END


GO
/****** Object:  StoredProcedure [dbo].[SP_Get_AgentScriptById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 Create  procedure [dbo].[SP_Get_AgentScriptById] @scriptId int , @dealer_id int
 as  
 begin
Select * from AgentScripts where AgentScriptID =@scriptId and DealerId= @dealer_id
 end


GO
/****** Object:  StoredProcedure [dbo].[Sp_Get_AllAgentScriptsForDropDown]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Get_AllAgentScriptsForDropDown] 
@dealer_id int
as begin 
Select AgentScriptID,AgentScriptName from AgentScripts where IsActive=1 and Enable=1 and DealerId=@dealer_id;

end


GO
/****** Object:  StoredProcedure [dbo].[Sp_Get_AllEmailConfigsForDropDown]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[Sp_Get_AllEmailConfigsForDropDown] @tenant_id int , @dealer_id int 
as begin 
Select EmailConfigID,Name from EmailConfiguration where IsActive=1 and TenantId = @tenant_id and DealerId = @dealer_id;
end











GO
/****** Object:  StoredProcedure [dbo].[Sp_Get_AllEmailTemplatesForDropDown]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[Sp_Get_AllEmailTemplatesForDropDown] 
@dealer_id int
as begin 
Select EmailTemplateID,EmailTemplateName from EmailTemplates where IsActive=1 and DealerId=@dealer_id;

end












GO
/****** Object:  StoredProcedure [dbo].[Sp_Get_AllSMSConfigsForDropDown]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   procedure [dbo].[Sp_Get_AllSMSConfigsForDropDown] 
as begin 
Select SMSConfigId,SMSConfigName from SMSConfiguration where IsActive=1

end












GO
/****** Object:  StoredProcedure [dbo].[Sp_Get_AllSMSTemplatesForDropDown]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   procedure [dbo].[Sp_Get_AllSMSTemplatesForDropDown] 
@dealer_id int 
as begin 
Select SMSTemplateID,SMSTemplateName from SMSTemplates where IsActive=1 and DealerId = @dealer_id;

end












GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CallDispositionCount]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Get_CallDispositionCount]
@campaignId int,
@mapid int,
@dialCondition int,
@dialAttempt int

AS
BEGIN

declare @query nvarchar(max);
declare @count_query nvarchar(max);
declare @where_clause nvarchar(max);
declare @group_by nvarchar(100);

set @group_by = ' group by CallResult';
set @count_query = 'select CallResult,  Count(CallResult) as count from Import_List_Table_'+ cast(@campaignId as nvarchar(max))+' as il ' 
set @where_clause = 'where il.MapId = '+ cast(@mapid as nvarchar(max))

 if(@dialCondition = 1)
 begin 
 set @where_clause = @where_clause + 'AND il.AttemptsMade < ' + cast(@dialAttempt AS nvarchar(10));
 end

 if(@dialCondition = 2)
 BEGIN
 SET @where_clause = @where_clause + 'AND il.AttemptsMade > ' + cast(@dialAttempt AS nvarchar(10));
 END

 if(@dialAttempt = 3)
 BEGIN
 SET @where_clause = @where_clause + 'AND il.AttemptsMade = ' + cast(@dialAttempt AS nvarchar(10));
 END

 SET @query= @count_query + @where_clause + @group_by;
 print @query
 exec(@query)
 END






GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CampaignContact_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_CampaignContact_List] 
@tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);                        
		declare @where_clause nvarchar(max);                       
	                                                                 
		set @count_query = 'select @total_records = COUNT(*) FROM CampaignContact_List';
		set @where_clause = ' map inner join Contact_List list on map.ListId = list.Id inner join Dealer d on list.DealerId=d.DealerId   WHERE map.IsActive = 1 and list.IsActive = 1 and d.IsActive=1 and map.TenantId ='+cast(@tenant_id as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'Status' or @filter_col = 'ListId'))  
		begin
			set @where_clause = @where_clause +' AND map.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end

		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_CampaignContactList AS(SELECT ROW_NUMBER() OVER(ORDER BY CampaignList_Id desc) AS RowNumber  ,map.*,list.Name as ContactList FROM CampaignContact_List ' + @where_clause + ') SELECT *  FROM All_CampaignContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CampaignContact_List_byCampaignID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_Get_CampaignContact_List_byCampaignID] @tenant_id int,@campaignId int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(*) FROM CampaignContact_List';
		set @where_clause = ' map inner join Contact_List list on map.ListId = list.Id inner join Dealer d on list.DealerId=d.DealerId   WHERE map.IsActive = 1 and list.IsActive = 1 and d.IsActive=1 and map.TenantId ='+cast(@tenant_id as varchar) +'and map.CampaignId='+cast(@campaignId as varchar) ;
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'Status'or @filter_col = 'ListId'))  
		begin
			set @where_clause = @where_clause +' AND map.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_CampaignContactList AS(SELECT ROW_NUMBER() OVER(ORDER BY CampaignList_Id desc) AS RowNumber  ,map.*,list.Name as ContactList FROM CampaignContact_List ' + @where_clause + ') SELECT *  FROM All_CampaignContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CampaignContact_ListById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_CampaignContact_ListById] @Id int as
begin 
--Select * from CampaignContact_List where CampaignList_Id=@Id
Select * from CampaignContact_List ccl 
inner join Contact_List cl on ccl.ListId=cl.Id
inner join Dealer d on cl.DealerId=d.DealerId
where d.IsActive=1 and CampaignList_Id=@Id
end













GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CampaignContact_ListById_Preview]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Get_CampaignContact_ListById_Preview] @Id int as
begin 
Select * from PreviewCampaignContact_List pcl
inner join Dealer d on pcl.DealerId=d.DealerId
where pcl.CampaignList_Id=@Id and d.IsActive=1
end










GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CampaignContact_ListMapNew]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Get_CampaignContact_ListMapNew] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		
		set @where_clause = ' where list.IsActive = 1 and source.IsActive = 1     and dealer.IsActive = 1 and attempt.Status not in (8) and map.Status not in (8) and map.TenantId ='+cast(@tenant_id as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND map.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = 'select @total_records = count(*) from (
select 
  
	list.Name,
	map.ListId,
	map.CampaignList_Id as MapId,
	map.CampaignId,
	map.DialingPriority,
	sum(attempt.TotalRecords) as TotalRecords, 
	sum(attempt.TotalRecordImported) as ImportedRecords,
	sum(attempt.TotalDncFiltered) as ExcludedRecords,
	sum(attempt.TotalDuplicateFiltered) as DuplicateRecords,
	sum(attempt.TotalInvalid) as InvalidRecords	 ,
	map.CreatedOn,
	map.Status 
from CampaignContact_List map 
left join ContactList_ImportStatus attempt on attempt.ListId = map.CampaignList_Id
inner join Contact_List list on list.Id = map.ListId
inner join ImportList_Source source on source.Id = list.SourceId
inner join Dealer dealer on dealer.DealerId = list.DealerId
' + @where_clause + '
group by map.CampaignId, map.ListId,list.Name,map.CampaignList_Id,map.DialingPriority,map.CreatedOn,map.Status
) as t';
		set @count_query = @count_query  ;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_CampaignContactList AS(SELECT ROW_NUMBER() OVER(ORDER BY map.ListId desc) AS RowNumber  ,list.Name,
	map.ListId,
	map.CampaignList_Id as MapId,
	map.CampaignId,
	map.DialingPriority,
	sum(attempt.TotalRecords) as TotalRecords, 
	sum(attempt.TotalRecordImported) as ImportedRecords,
	sum(attempt.TotalDncFiltered) as ExcludedRecords,
	sum(attempt.TotalDuplicateFiltered) as DuplicateRecords,
	sum(attempt.TotalInvalid) as InvalidRecords	 ,
	map.CreatedOn,
	map.Status 
from CampaignContact_List map 
inner join ContactList_ImportStatus attempt on attempt.ListId = map.CampaignList_Id
inner join Contact_List list on list.Id = map.ListId
inner join ImportList_Source source on source.Id = list.SourceId
inner join Dealer dealer on dealer.DealerId = list.DealerId ' + @where_clause + ' group by map.CampaignId, map.ListId,list.Name,map.CampaignList_Id,map.DialingPriority,map.CreatedOn,map.Status ) SELECT *  FROM All_CampaignContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
	exec(@main_query);
		--select(@main_query);
		--print(@main_query);
	end
	else
		set @total_records = 0;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CampaignContact_ListNew]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Get_CampaignContact_ListNew] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = count(*) from (
select 
min(map.DialingPriority) as DialingPriority ,

list.Name,
map.ListId,
map.CampaignId,
sum(attempt.TotalRecords) as TotalRecords, 
sum(attempt.TotalRecordImported) as ImportedRecords,
sum(attempt.TotalDncFiltered) as ExcludedRecords,
sum(attempt.TotalDuplicateFiltered) as DuplicateRecords,
sum(attempt.TotalInvalid) as InvalidRecords	
from CampaignContact_List map 
inner join ContactList_ImportStatus attempt on attempt.ListId = map.CampaignList_Id
inner join Contact_List list on list.Id = map.ListId
inner join ImportList_Source source on source.Id = list.SourceId
inner join Dealer dealer on dealer.DealerId = list.DealerId
where list.IsActive = 1 and source.IsActive = 1 and dealer.IsActive = 1 and attempt.Status not in (8) and map.Status not in (8)
group by map.CampaignId, map.ListId,list.Name 
) as t';
		set @where_clause = ' where list.IsActive = 1 and source.IsActive = 1 and dealer.IsActive = 1 and attempt.Status not in (8) and map.Status not in (8) and map.TenantId ='+cast(@tenant_id as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND map.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query ;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_CampaignContactList AS(SELECT ROW_NUMBER() OVER(ORDER BY map.ListId desc) AS RowNumber  ,list.Name,
map.ListId,
min(map.DialingPriority) as DialingPriority,

map.CampaignId,
sum(attempt.TotalRecords) as TotalRecords, 
sum(attempt.TotalRecordImported) as ImportedRecords,
sum(attempt.TotalDncFiltered) as ExcludedRecords,
sum(attempt.TotalDuplicateFiltered) as DuplicateRecords,
sum(attempt.TotalInvalid) as InvalidRecords	
from CampaignContact_List map 
inner join ContactList_ImportStatus attempt on attempt.ListId = map.CampaignList_Id
inner join Contact_List list on list.Id = map.ListId
inner join ImportList_Source source on source.Id = list.SourceId
inner join Dealer dealer on dealer.DealerId = list.DealerId ' + @where_clause + ' group by map.CampaignId, map.ListId,list.Name) SELECT *  FROM All_CampaignContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
		--select(@main_query);
		--print(@main_query);
	end
	else
		set @total_records = 0;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Contact_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_Contact_List] @tenant_id int,@dealerId int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null,@autogenerated bit = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM Contact_List cl inner join ImportList_Source src on src.Id = cl.SourceId';
		set @where_clause = ' WHERE cl.IsActive = 1 AND src.IsActive = 1 AND src.TenantId = '+cast(@tenant_id as varchar)+'and cl.DealerId='+cast(@dealerId as varchar);
		if(@filter_col is not null and @filter_by is not null)  
		begin
			if(@filter_col = 'SourceId')
			begin
				set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			end
			else if(@filter_col = 'Purpose')
			begin
				set @where_clause = @where_clause + ' AND '+ +cast(@filter_by as varchar) + ' = (' +@filter_col + ' & '+cast(@filter_by as varchar)+')';
			end
			
		end
		 if(@autogenerated is not null)
			begin
				set @where_clause = @where_clause +' AND cl.AutoGenerated = '+cast(@autogenerated as varchar);
			end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND cl.Name like ''%'+@search_term+'%''';
		end
		set @where_clause = @where_clause + 'and dbo.SourceState(SourceId) = 1'
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactList AS (SELECT ROW_NUMBER() OVER(ORDER BY cl.Id DESC) AS RowNumber ,cl.*,src.Name as SourceName,src.Type FROM Contact_List cl inner join ImportList_Source src on cl.SourceId = src.Id' + @where_clause + ') SELECT * FROM All_ContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		end
	else
		set @total_records = 0;
END








GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Contact_List_masthan]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_Get_Contact_List_masthan] @tenant_id int,@dealerId int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null,@autogenerated bit = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM Contact_List cl inner join ImportList_Source src on src.Id = cl.SourceId';
		set @where_clause = ' WHERE cl.IsActive = 1 AND src.IsActive = 1 AND src.TenantId = '+cast(@tenant_id as varchar)+'and cl.DealerId='+cast(@dealerId as varchar);
		
	/*	if(@filter_col is not null and @filter_by is not null)  
		begin
			if(@filter_col = 'SourceId')
			begin
				set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			end
			else if(@filter_col = 'Purpose')
			begin
				set @where_clause = @where_clause + ' AND '+ +cast(@filter_by as varchar) + ' = (' +@filter_col + ' & '+cast(@filter_by as varchar)+')';
			end
			
		end
		 if(@autogenerated is not null)
			begin
				set @where_clause = @where_clause +' AND cl.AutoGenerated = '+cast(@autogenerated as varchar);
			end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND cl.Name like ''%'+@search_term+'%''';
		end   */
		set @where_clause = @where_clause + 'and dbo.SourceState(SourceId) = 1'
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactList AS (SELECT ROW_NUMBER() OVER(ORDER BY cl.Id DESC) AS RowNumber ,cl.*,src.Name as SourceName,src.Type FROM Contact_List cl inner join ImportList_Source src on cl.SourceId = src.Id' + @where_clause + ') SELECT * FROM All_ContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		end
	else
		set @total_records = 0;
END








GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Contact_ListById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_Contact_ListById] @Id int as
begin 
Select list.*,src.Name as SourceName,src.Type from Contact_List list 
inner join ImportList_Source src on list.SourceId = src.Id
inner join Dealer d on list.DealerId=d.DealerId
where list.Id=@Id and d.IsActive=1
end











GO
/****** Object:  StoredProcedure [dbo].[sp_get_contactlist_Masthan]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[sp_get_contactlist_Masthan]

@tenant_id int ,
@dealerid int ,
@page_no int ,
@records_per_page int ,
@total_records int output

AS
BEGIN
IF(dbo.TenantState(@tenant_id)=1)
BEGIN
Declare @count_query nvarchar(max);
Declare @main_query nvarchar(max);
Declare @where_clause nvarchar(max);
SET @count_query = 'SELECT @toatl_records=count(*) FROM Contact_List CL INNER JOIN ImportList_Source ILS ON ILS.Id=CL.SourceId';
SET @where_clause = 'WHERE CL.IsActive=1 and ILS.IsActive=1 and ILS.TenantId='+cast(@tenant_id as varchar)+'and ILS.DealerId='+cast(@dealerid as varchar);
SET @where_clause = @where_clause + 'and dbo.SourceState(SourceId) = 1'
SET @count_query = @count_query + @where_clause;
execute sp_executesql @count_query, N'@total_records int output',@total_records output;
SET @main_query = 'WITH All_ContactList AS (SELECT ROW_NUMBER() OVER(ORDER BY CL.Id DESC) AS RowNumber ,CL.*,ILS.Name as SourceName,ILS.Type FROM Contact_List CL inner join ImportList_Source ILS on CL.SourceId = ILS.Id' + @where_clause + ') SELECT * FROM All_ContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		print @main_query
		end
	else
		set @total_records = 0;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_ContactMapAppendConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_ContactMapAppendConfig] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @sort_col nvarchar(100) = null, @sort_direction nvarchar(10) = 'desc', @total_records int output
as begin
	
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM ContactMapAppendConfig  ';
		set @where_clause = ' ap inner join Contact_List cl on cl.Id=ap.AppendedListId where cl.IsActive=1 ' ;
		
		if(@filter_col is not null and @filter_by is not null and ((@filter_col = 'Status') or (@filter_col = 'CampaignId')))  
		begin
			set @where_clause = @where_clause + ' and ' + @filter_col + ' = '+cast(@filter_by as varchar);
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactMapAppendConfig AS (SELECT ROW_NUMBER() OVER(ORDER BY ap.Id DESC) AS RowNumber ,ap.* FROM ContactMapAppendConfig ' + @where_clause + ') SELECT * FROM All_ContactMapAppendConfig WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';	
		if(@sort_col is not null and (@sort_col = 'LastUpdatedOn' or @sort_col = 'CreatedOn'))
		begin
			set @main_query = @main_query + ' ORDER BY '+@sort_col + ' '+@sort_direction;
		end
		exec(@main_query)
		print(@main_query)
	end
	else
		set @total_records = 0;
END










GO
/****** Object:  StoredProcedure [dbo].[SP_Get_ContactMapAppendConfig_ById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_Get_ContactMapAppendConfig_ById] @Id int as
begin 
Select * from ContactMapAppendConfig  ap inner join Contact_List cl on cl.Id=ap.AppendedListId where cl.IsActive=1 and ap.Id=@Id
end





GO
/****** Object:  StoredProcedure [dbo].[SP_Get_ContactMapGroup_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_ContactMapGroup_List]  @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin

		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM ContactMapGroup cm inner join Contact_List cl on cm.ListId=cl.Id ';
		set @where_clause = ' where cm.IsActive=1 and cl.IsActive=1';
		
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'ListId'))  
		begin
			set @where_clause = @where_clause+'and cm.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId'))  
		begin
			set @where_clause =@where_clause+'and cm.'+ @filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause+'and cm.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND Name like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_ContactMapGroup AS(SELECT ROW_NUMBER() OVER(ORDER BY cm.Id DESC) AS RowNumber,cm.*,cl.Name as ContactList, ce.Name as Campaign   from ContactMapGroup cm
	inner Join Contact_List cl on cl.Id=cm.ListId 
    inner Join CampaignExtraDetails ce on ce.CampaignId=cm.CampaignId
	' + @where_clause + ') select * FROM  All_ContactMapGroup WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		print @main_query
	end




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_ContactMapGroupIteration_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_ContactMapGroupIteration_List]  @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null,@total_records int output
as begin

		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM ContactMapGroupIteration cmgi';
		set @where_clause = '  where cmgi.Id is not null  ';
		
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'GroupId'))  
		begin
			set @where_clause = @where_clause+'and cmgi.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'MapId'))  
		begin
			set @where_clause =@where_clause+'and cmgi.'+ @filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause+'and cmgi.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_ContactMapGroupIteration AS(SELECT ROW_NUMBER() OVER(ORDER BY cmgi.Id DESC) AS RowNumber,cmgi.* from ContactMapGroupIteration cmgi
	inner Join ContactMapGroup cmg on cmg.Id=cmgi.GroupId 
    inner Join CampaignContact_List cm on cm.CampaignList_Id=cmgi.MapId
	' + @where_clause + ') select * FROM  All_ContactMapGroupIteration WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		
	end





GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CustomDNCMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_Get_CustomDNCMap] @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output
as begin

		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM CustomDNCMapTable';
		set @where_clause = ' WHERE IsActive = 1 ';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId'))  
		begin
			set @where_clause = @where_clause +' AND ('+@filter_col + ' = '+cast(@filter_by as varchar)+' OR CampaignId < 1)';
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCMapId DESC) AS RowNumber ,*  FROM CustomDNCMapTable ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CustomDNCMapTable]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[SP_Get_CustomDNCMapTable] @DNC_Id int as
BEGIN
		SELECT * from CustomDNCMapTable cdm
		inner join Dealer d on cdm.DealerId= d.DealerId		
		WHERE DNCMapId =@DNC_Id and d.IsActive=1
END	




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CustomDNCMaruti_By_ID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[SP_Get_CustomDNCMaruti_By_ID] @DNC_Id int as
BEGIN
		SELECT * from CustomDNCMaruti cdm
		inner join Dealer d on cdm.DealerId= d.DealerId		
		WHERE DNCId =@DNC_Id and d.IsActive=1
END	











GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CustomDNCMarutiList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_CustomDNCMarutiList] @dealerId  int ,@tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM CustomDNCMaruti CDM   ';
		set @where_clause = 'INNER JOIN CampaignExtraDetails CE ON CDM.CampaignId=CE.CampaignId WHERE CE.IsActive=1 and CDM.IsActive = 1 AND CDM.TenantId = '+cast(@tenant_id as varchar)+'AND CDM.DealerId='+cast(@dealerId as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId'))  
		begin
			set @where_clause = @where_clause +' AND (CDM.'+@filter_col + ' = '+cast(@filter_by as varchar)+' OR CDM.CampaignId < 1)';
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'status'))  
		begin
			set @where_clause = @where_clause +' AND CDM.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND CDM.PhoneNumber like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCId DESC) AS RowNumber ,CDM.*  FROM CustomDNCMaruti CDM ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	else
		set @total_records = 0
END










GO
/****** Object:  StoredProcedure [dbo].[SP_Get_CustomDNCMarutiListForAllDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_CustomDNCMarutiListForAllDealer]@tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM CustomDNCMaruti';
		set @where_clause = ' WHERE IsActive = 1 AND TenantId = '+cast(@tenant_id as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId'))  
		begin
			set @where_clause = @where_clause +' AND ('+@filter_col + ' = '+cast(@filter_by as varchar)+' OR CampaignId < 1)';
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND PhoneNumber like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCId DESC) AS RowNumber ,*  FROM CustomDNCMaruti ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	else
		set @total_records = 0
END








GO
/****** Object:  StoredProcedure [dbo].[SP_Get_DNC_By_ID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Get_DNC_By_ID] @DNC_Id int as
BEGIN
		SELECT DNCId,PhoneNumber,CampaignId from CustomDNC WHERE DNCId =@DNC_Id
END	



















GO
/****** Object:  StoredProcedure [dbo].[SP_Get_DNCList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[SP_Get_DNCList] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM CustomDNC';
		set @where_clause = ' WHERE IsActive = 1 AND TenantId = '+cast(@tenant_id as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId'))  
		begin
			set @where_clause = @where_clause +' AND ('+@filter_col + ' = '+cast(@filter_by as varchar)+' OR CampaignId < 1)';
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND PhoneNumber like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCId DESC) AS RowNumber ,DNCId,PhoneNumber,CampaignId  FROM CustomDNC ' + @where_clause + ') SELECT DNCId, PhoneNumber,CampaignId FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	else
		set @total_records = 0
END













GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Email_Configuration]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_Email_Configuration] @tenant_id int,@page_no int, @records_per_page int, @total_records int output,@dealer_id int
as begin
if(dbo.TenantState(@tenant_id) = 1)
	begin
select @total_records = COUNT(*) FROM EmailConfiguration where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id;
	WITH All_EmailConfiguration AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY EmailConfigID DESC) AS RowNumber , *  FROM EmailConfiguration where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id
	) SELECT * FROM All_EmailConfiguration WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
	end
	else
		set @total_records = 0
END















GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Email_Templates]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_Get_Email_Templates] @tenant_id int,@page_no int, @records_per_page int, @total_records int output ,@dealer_id int
as begin
if(dbo.TenantState(@tenant_id) = 1)
	begin
select @total_records = COUNT(*) FROM EmailTemplates where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id;
	WITH All_EmailTemplates AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY EmailTemplateID ASC) AS RowNumber , *  FROM EmailTemplates where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id
	) SELECT * FROM All_EmailTemplates WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
	end
	else
		set @total_records = 0
END












GO
/****** Object:  StoredProcedure [dbo].[SP_Get_EmailConfigById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_EmailConfigById] @configId int
 as  
 begin
Select * from EmailConfiguration where EmailConfigID =@configId

 end














GO
/****** Object:  StoredProcedure [dbo].[SP_Get_EmailTemplateById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 CREATE  procedure [dbo].[SP_Get_EmailTemplateById] @templateId int , @dealer_id int
 as  
 begin
Select * from EmailTemplates where EmailTemplateID =@templateId and DealerId= @dealer_id
 end











GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Exclusion_DNCList_CSV]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[SP_Get_Exclusion_DNCList_CSV] @dealerId int
as
begin
select PhoneNumber,CampaignName = (select Name from [dbo].[CampaignExtraDetails] where CampaignId = cDNC.CampaignId)
from CustomDNCMaruti as cDNC where IsActive=1 and status=2 and DealerId=@dealerId
end




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Global_DNC_By_ID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_Global_DNC_By_ID] 
	@id uniqueidentifier
as begin
	select * from Global_DNC where DNCId = @id
end






GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Global_DNCList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_Global_DNCList] 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@search_term nvarchar(100) = null, 
	@total_records int output
as begin
	
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM Global_DNC';
		set @where_clause = ' WHERE IsActive = 1 ';
	
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'DNCRuleId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND PhoneNumber like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCId DESC) AS RowNumber ,*  FROM Global_DNC ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	
END







GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Global_DNCList_CSV]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_Global_DNCList_CSV] 
as 
begin
	Select PhoneNumber from Global_DNC where IsActive=1 and Status= 2
END




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_GlobalDNC_By_ID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Get_GlobalDNC_By_ID] @id uniqueidentifier as
BEGIN
		SELECT * from GlobalDNC WHERE DNCId =@id
END	






GO
/****** Object:  StoredProcedure [dbo].[SP_Get_GlobalDNCAutomation_FolderPath]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,Nitesh>
-- Create date: <Create Date,06-02-2024>
-- Description:	<Description get folder path>
-- =============================================
CREATE  procedure [dbo].[SP_Get_GlobalDNCAutomation_FolderPath]
 as  
 begin
SELECT TOP 1 * FROM Global_DNCAutomation  where IsActive=1 ORDER BY DNCId DESC;
 end


GO
/****** Object:  StoredProcedure [dbo].[SP_Get_GlobalDNCList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_GlobalDNCList] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM GlobalDNC';
		set @where_clause = ' WHERE IsActive = 1 AND TenantId = '+cast(@tenant_id as varchar);
	
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CreatedOn'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'DNCRuleId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND PhoneNumber like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCId DESC) AS RowNumber ,*  FROM GlobalDNC ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	else
		set @total_records = 0
END







GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Holiday_By_ID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Get_Holiday_By_ID] @Holiday_Id int as
BEGIN
		SELECT HolidayId,HolidayName,HolidayDescription,HolidayStartDate,HolidayEndDate,CampaignId from HolidayDetails WHERE HolidayId =@Holiday_Id
END	

















GO
/****** Object:  StoredProcedure [dbo].[SP_Get_HolidayList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Get_HolidayList] @tenant_id int, @page_no int, @records_per_page int, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		select @total_records = COUNT(*) FROM HolidayDetails where IsActive = 1 and TenantId = @tenant_id;
		WITH All_Holidays AS
		(
			SELECT ROW_NUMBER() OVER(ORDER BY HolidayId ASC) AS RowNumber , HolidayId, HolidayName,HolidayDescription, HolidayStartDate,HolidayEndDate,CampaignId  FROM HolidayDetails where IsActive = 1 and TenantId = @tenant_id
		) SELECT HolidayId, HolidayName,HolidayDescription, HolidayStartDate,HolidayEndDate,CampaignId FROM All_Holidays WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
		end
	else
		set @total_records = 0
END



















GO
/****** Object:  StoredProcedure [dbo].[SP_Get_ImportList_Source]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_ImportList_Source] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @autogenerated bit = null,@dealerId int, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM ImportList_Source';
		set @where_clause = ' WHERE IsActive = 1 AND TenantId = '+cast(@tenant_id as varchar)+'And DealerId='+cast(@dealerId as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Type') )  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND Name like ''%'+@search_term+'%''';
		end
		if(@autogenerated is not null)
			begin
				set @where_clause = @where_clause +' AND AutoGenerated = '+cast(@autogenerated as varchar);
			end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ImpostListSource AS (SELECT ROW_NUMBER() OVER(ORDER BY Id DESC) AS RowNumber ,Id,Name,Type,Configuration,CreatedOn,IsActive, LastUpdatedOn, TenantId,DealerId FROM ImportList_Source ' + @where_clause + ') SELECT Id, Name,Type,Configuration,CreatedOn,LastUpdatedOn,DealerId, TenantId, IsActive FROM All_ImpostListSource WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
END







GO
/****** Object:  StoredProcedure [dbo].[SP_Get_ImportList_SourceById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_ImportList_SourceById] @Id int as
begin 
Select * from ImportList_Source ils
inner join Dealer d on ils.DealerId=d.DealerId
where Id=@Id and d.IsActive=1
end














GO
/****** Object:  StoredProcedure [dbo].[sp_get_License_detail_and_Available]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[sp_get_License_detail_and_Available] 
as
declare @id int=0;
  declare @totallicense int=0;
  declare @usedLicense int=0;
  begin
	   set @id=(select MAX(Id) from License_Master_UniAgent);
	   set @totallicense= (select (TotalLicense) from License_Master_UniAgent where Id=@id);
	   set @usedLicense=(select (UsedLicense) from License_Master_UniAgent where Id=@id);
	   
	   
	   select @totallicense as TotalLicense,@usedLicense as UsedLicense,case when @totallicense>@usedLicense then @totallicense-@usedLicense else 0  end as AvailableLicenses


  end


GO
/****** Object:  StoredProcedure [dbo].[sp_get_License_detail_so_far]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[sp_get_License_detail_so_far]
as
declare @id int=0;
  declare @totallicense int=0;
  declare @usedLicense int=0;
  begin
	   set @id=(select MAX(Id) from License_Master_UniAgent);
	   set @totallicense= (select (TotalLicense) from License_Master_UniAgent where Id=@id);
	   set @usedLicense=(select (UsedLicense) from License_Master_UniAgent where Id=@id);
	   
	   
	   select @totallicense as TotalLicense,@usedLicense as UsedLicense,case when @totallicense>@usedLicense then (@usedLicense*100/@totallicense) else 0 end as LicenseUtilizedPer 
  end




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_MultiContact_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[SP_Get_MultiContact_List] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(*) FROM MultiContactListConfig';
		set @where_clause = ' WHERE IsActive = 1 AND TenantId = '+cast(@tenant_id as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_MultiContactListConfig AS(SELECT ROW_NUMBER() OVER(ORDER BY MultiListId DESC) AS RowNumber ,* FROM MultiContactListConfig ' + @where_clause + ') SELECT *  FROM All_MultiContactListConfig WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
END











GO
/****** Object:  StoredProcedure [dbo].[SP_Get_MultiContactListConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_MultiContactListConfig] @tenant_id int,@dealerId int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM MultiContactListConfig cl inner join ImportList_Source src on src.Id = cl.SourceId';
		set @where_clause = ' WHERE cl.IsActive = 1 AND src.IsActive = 1 AND src.TenantId = '+cast(@tenant_id as varchar)+'And cl.DealerId='+cast(@dealerId as varchar);
		if(@filter_col is not null and @filter_by is not null)  
		begin
			if(@filter_col = 'SourceId')
			begin
				set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			end
			else if(@filter_col = 'Purpose')
			begin
				set @where_clause = @where_clause + ' AND '+ +cast(@filter_by as varchar) + ' = (' +@filter_col + ' & '+cast(@filter_by as varchar)+')';
			end
			else if(@filter_col = 'Status')
			begin
				set @where_clause = @where_clause + ' AND '+ +cast(@filter_by as varchar) + ' = (' +@filter_col + ' & '+cast(@filter_by as varchar)+')';
			end
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND cl.Name like ''%'+@search_term+'%''';
		end
		set @where_clause = @where_clause + 'and dbo.SourceState(SourceId) = 1'
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_MutiContactList AS (SELECT ROW_NUMBER() OVER(ORDER BY cl.MultiListId DESC) AS RowNumber ,cl.*,src.Name as SourceName FROM MultiContactListConfig cl inner join ImportList_Source src on cl.SourceId = src.Id' + @where_clause + ') SELECT * FROM All_MutiContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		end
	else
		set @total_records = 0;
END









GO
/****** Object:  StoredProcedure [dbo].[SP_Get_MultipleContact_ListById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[SP_Get_MultipleContact_ListById] @Id int as
begin 
Select * from MultiContactListConfig where MultiListId=@Id
end
















GO
/****** Object:  StoredProcedure [dbo].[SP_Get_MultipleGlobalDNCMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[SP_Get_MultipleGlobalDNCMap] 
@page_no int, 
@records_per_page int, 
@filter_col nvarchar(100) = null,
@filter_by int = null, 
@total_records int output
as
begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);

		set @where_clause = ' ';
		set @count_query = 'select @total_records = COUNT(*) FROM GlobalDNCMap';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = ' WHERE ' +@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',
		@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCMapId DESC) AS RowNumber,*  FROM GlobalDNCMap ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN 
		(('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		print @main_query
end




GO
/****** Object:  StoredProcedure [dbo].[SP_Get_NationalDNC_By_ID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_Get_NationalDNC_By_ID] @id int as
BEGIN
		SELECT * from NationalDNC WHERE DNCId =@id
END	








GO
/****** Object:  StoredProcedure [dbo].[SP_Get_NationalDNCById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_NationalDNCById] 
	@id int
as begin
select * from NationalDNC where IsActive=0 and DNCId=@id
end









GO
/****** Object:  StoredProcedure [dbo].[SP_Get_NationDNCList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_NationDNCList] @dealerId  int ,@tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM NationalDNC';
		set @where_clause = ' WHERE IsActive = 1 AND TenantId = '+cast(@tenant_id as varchar)+'AND DealerId='+cast(@dealerId as varchar);
	
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CreatedOn'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND PhoneNumber like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_DNCs AS(SELECT ROW_NUMBER() OVER(ORDER BY DNCId DESC) AS RowNumber ,*  FROM NationalDNC ' + @where_clause + ') SELECT * FROM All_DNCs WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	else
		set @total_records = 0
END







GO
/****** Object:  StoredProcedure [dbo].[SP_Get_PreviewCampaignContact_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_PreviewCampaignContact_List] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(*) FROM PreviewCampaignContact_List';
		set @where_clause = ' WHERE IsActive = 1 and dbo.ListState(ListId) = 1 AND TenantId = '+cast(@tenant_id as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_CampaignContactList AS(SELECT ROW_NUMBER() OVER(ORDER BY CampaignList_Id DESC) AS RowNumber ,* FROM PreviewCampaignContact_List ' + @where_clause + ') SELECT *  FROM All_CampaignContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
END
















GO
/****** Object:  StoredProcedure [dbo].[SP_Get_RechurnPolicy_Map_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_RechurnPolicy_Map_List]  @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin

		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM RechurnPolicyMap';
		set @where_clause = '  where  IsActive=1 ';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'PolicyId'))  
		begin
			set @where_clause = @where_clause+'and '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Campaign'))  
		begin
			set @where_clause =@where_clause+'and'+ @filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause+'and '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND Name like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_RechurnPolicyMaps AS(SELECT ROW_NUMBER() OVER(ORDER BY Id DESC) AS RowNumber ,Id,PolicyId,Campaign,ContactMap,Status,CreatedOn,LastUpdatedon from RechurnPolicyMap ' + @where_clause + ') select * FROM  All_RechurnPolicyMaps WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end





GO
/****** Object:  StoredProcedure [dbo].[SP_Get_RechurnPolicyList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_RechurnPolicyList]  @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin

		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM RechurnPolicy';
		set @where_clause = '  where  IsActive=1 ';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'DealerId'))  
		begin
			set @where_clause = @where_clause+'and '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Schedule'))  
		begin
			set @where_clause =@where_clause+'and  '+ @filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause =@where_clause+'and  '+ @filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND Name like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query ='WITH All_RechurnPolicys AS (SELECT ROW_NUMBER() OVER(ORDER BY Id DESC) AS RowNumber ,Id,Name,Description,Schedule,IsManual,AgentDispositionsDetailsXml,CallResultsDetailsXml,Status,CreatedOn,LastUpdatedOn,DealerId,DialAttempt,DialAttemptCondition FROM RechurnPolicy  ' + @where_clause + ') SELECT * FROM All_RechurnPolicys WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end





GO
/****** Object:  StoredProcedure [dbo].[SP_Get_RecurrenceScheduleById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_Get_RecurrenceScheduleById]
@id int
as Begin
Select * from [dbo].[RecurrenceSchedule] where Id=@id
end





GO
/****** Object:  StoredProcedure [dbo].[SP_Get_RoleList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_Get_RoleList] @tenant_id int,@page_no int,@records_per_page int,@total_records int output
 as
  
 begin 
  if(dbo.TenantState(@tenant_id)=1)
  begin 
  Select @total_records=COUNT(*) from Role_Master where IsActive=1  and TenantId=@tenant_id;
  WITH All_Roles AS
  (
  Select ROW_NUMBER() Over (order by RoleId ASC) As RowNumber,RM.* from Role_Master RM where RM.IsActive=1 and RM.TenantId=@tenant_id
  )Select * from All_Roles where RowNumber Between ((@page_no-1)* @records_per_page)+1 AND @records_per_page *(@page_no)
  end
  else set @total_records=0;
 end









GO
/****** Object:  StoredProcedure [dbo].[SP_Get_Seq_ListName]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_Get_Seq_ListName] @sequenceid intasbegin set nocount on;select SequenceId,max(Id) as ID  into #recordsfrom ContactListSequenceIteration where SequenceId=@sequenceid group by SequenceId ;select cc.SequenceId,AutogeneratedFileName as latestFileName from ContactListSequenceIteration cc inner join #records r on cc.Id=r.ID and cc.SequenceId=r.SequenceIddrop table #records;end
GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SingleUser_By_ID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Get_SingleUser_By_ID] @user_id int as
BEGIN
		SELECT UM.*,TM.Name as Tenant FROM UserMaster UM INNER JOIN Tenants TM ON UM.TenantId = TM.Id  WHERE UM.UserId = @user_id 
END	















GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SkillUnAssignedList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_SkillUnAssignedList] 
as begin
Select * from UCCE_Skill_Group a where not exists(Select 1 from DealerExtraDetails d where a.SkillTargetID=d.SkillTargetID and d.IsActive=1) and a.Deleted!='Y'
end






GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SkillUnAssignedList_ByDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_SkillUnAssignedList_ByDealer] @dealerId int 
as begin
Select * from UCCE_Skill_Group a where not exists(Select 1 from DealerExtraDetails d where a.SkillTargetID=d.SkillTargetID and d.IsActive=1 and d.DealerId=@dealerId) and a.Deleted!='Y'
end






GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SkillUnAssignedList_ByDealerName]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Get_SkillUnAssignedList_ByDealerName] @search_term nvarchar(255) 
as begin
Select * from UCCE_Skill_Group a where not exists(Select 1 from DealerExtraDetails d where a.SkillTargetID=d.SkillTargetID and d.IsActive=1 ) and a.Deleted!='Y'and a.EnterpriseName like (+@search_term+'%')
end







GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SkillUnAssignedList_ByDealerName1]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Get_SkillUnAssignedList_ByDealerName1] @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output ,@search_term nvarchar(255) 
as begin
declare @MainQuery nvarchar(max);
declare @subquery nvarchar(max);



set @MainQuery= 'With All_RequiredLit As(Select ROW_NUMBER() OVER(ORDER BY a.SkillTargetID DESC) AS RowNumber, * from UCCE_Skill_Group a where not exists(Select 1 from DealerExtraDetails d where a.SkillTargetID=d.SkillTargetID and d.IsActive=1 ) and a.Deleted!=''Y'' and a.EnterpriseName like ('''+@search_term+'%'')) Select * from All_RequiredLit where RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
execute(@MainQuery);
end







GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SMS_Config]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  CREATE  procedure [dbo].[SP_Get_SMS_Config] @tenant_id int,@page_no int, @records_per_page int, @total_records int output , @dealer_id int
as begin
if(dbo.TenantState(@tenant_id) = 1)
	begin
select @total_records = COUNT(*) FROM SMSConfiguration where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id;
	WITH All_SMSConfigs AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY SMSConfigId DESC) AS RowNumber , *  FROM SMSConfiguration where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id  
	) SELECT * FROM All_SMSConfigs WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
	end
	else
		set @total_records = 0
END











GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SMS_Templates]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE  procedure [dbo].[SP_Get_SMS_Templates] @tenant_id int,@page_no int, @records_per_page int, @total_records int output , @dealer_id int 
as begin
if(dbo.TenantState(@tenant_id) = 1)
	begin
select @total_records = COUNT(*) FROM SMSTemplates where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id;
	WITH All_SMSTemplates AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY SMSTemplateID ASC) AS RowNumber , *  FROM SMSTemplates where IsActive = 1 and TenantId = @tenant_id and DealerId = @dealer_id
	) SELECT * FROM All_SMSTemplates WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
	end
	else
		set @total_records = 0
END











GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SMSConfigById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   procedure [dbo].[SP_Get_SMSConfigById] @configId int , @dealer_id int
 as  
 begin
Select * from SMSConfiguration where SMSConfigId =@configId and DealerId = @dealer_id 
 end











GO
/****** Object:  StoredProcedure [dbo].[SP_Get_SMSTemplateById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE   procedure [dbo].[SP_Get_SMSTemplateById] @templateId int , @dealer_id int
 as  
 begin
Select * from SMSTemplates where SMSTemplateID =@templateId and DealerId = @dealer_id
 end











GO
/****** Object:  StoredProcedure [dbo].[SP_Get_StuckRecords]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[SP_Get_StuckRecords] @tenant_id int=1, @page_no int=1, @records_per_page int, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
CREATE TABLE #XMLTable (CampaignList_Id int ,attribute varchar(30), operator varchar(30) , value varchar(30) )

INSERT INTO #XMLTable (CampaignList_Id,attribute , operator , value )
SELECT
s.CampaignList_Id,
m.c.value('@attribute', 'varchar(max)') as attribute ,
m.c.value('@operator', 'varchar(max)') as operator,
m.c.value('@value', 'varchar(max)') as value
from CampaignContact_List as s
outer apply s.Filters.nodes('filter/conditions/condition') as m(c)


SELECT CCL.CampaignList_Id , CED.Name as Campaign_Name , CL.Name as List_Name ,TS.value , CLI.Lastattemptedon
from CampaignContact_List CCL
INNER JOIN Contact_List CL ON CCL.ListId=CL.Id
INNER JOIN ContactList_ImportStatus CLI ON CCL.CampaignList_Id=CLI.ListId
INNER JOIN CampaignExtraDetails CED ON CCL.CampaignId=CED.CampaignId
INNER JOIN #XMLTable TS ON CCL.CampaignList_Id=TS.CampaignList_Id
WHERE CCL.Status IN(1,5,7) and -DATEDIFF(MINUTE, getutcdate() , LastAttemptedOn)>15
AND CCL.IsActive=1 AND CL.IsActive=1


DROP TABLE #XMLTable
end
	else
		set @total_records = 0
END





GO
/****** Object:  StoredProcedure [dbo].[SP_Get_TenantList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_TenantList] @page_no int, @records_per_page int, @total_records int output
as begin
select @total_records = COUNT(*) FROM dbo.Tenants where IsActive = 1;
	WITH All_Tenants AS
	(
		SELECT ROW_NUMBER() OVER(ORDER BY Id ASC) AS RowNumber , Id, Name,Configuration,IsActive FROM dbo.Tenants where IsActive = 1
	) SELECT Id, Name,Configuration, IsActive FROM All_Tenants WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
END







GO
/****** Object:  StoredProcedure [dbo].[SP_Get_UniCampAgentList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_UniCampAgentList] @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM UCCEAgent';
	 set @where_clause='';
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_Agents AS(SELECT ROW_NUMBER() OVER(ORDER BY SkillTargetID DESC) AS RowNumber ,*  FROM UCCEAgent ' + @where_clause + ') SELECT * FROM All_Agents WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	








GO
/****** Object:  StoredProcedure [dbo].[SP_Get_UniCampSkillGroupList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_UniCampSkillGroupList] @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM UCCE_Skill_Group';
	 set @where_clause='';
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_Skills AS(SELECT ROW_NUMBER() OVER(ORDER BY SkillTargetID DESC) AS RowNumber ,*  FROM UCCE_Skill_Group ' + @where_clause + ') SELECT * FROM All_Skills WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end
	







GO
/****** Object:  StoredProcedure [dbo].[SP_Get_User_Master_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_User_Master_List] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM User_Master um inner join Dealer dl on dl.DealerId = um.DealerId ';
		set @where_clause = ' WHERE um.IsActive = 1 AND dl.IsActive = 1  AND dl.TenantId = '+cast(@tenant_id as varchar)+' AND um.TenantId = '+cast(@tenant_id as varchar);
		if(@filter_col is not null and @filter_by is not null)  
		begin
			if(@filter_col = 'RoleId')
			begin
				set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			end
			else if(@filter_col = 'DealerId')
			begin
				set @where_clause = @where_clause + ' AND '+ +cast(@filter_by as varchar) + ' = (' +@filter_col + ' & '+cast(@filter_by as varchar)+')';
			end
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND um.UserName like ''%'+@search_term+'%''';
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactList AS (SELECT ROW_NUMBER() OVER(ORDER BY um.UserId DESC) AS RowNumber ,um.*,dl.DealerName as DealerName,r.Name as RoleName FROM User_Master um inner join Dealer dl on um.DealerId = dl.DealerId inner join Role_Master r on um.RoleId=r.RoleId  ' + @where_clause + ') SELECT * FROM All_ContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		end
	else
		set @total_records = 0;
END









GO
/****** Object:  StoredProcedure [dbo].[SP_Get_User_Mster_List]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_User_Mster_List] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM User_Master um inner join Dealer dl on dl.DealerId = um.DealerId ';
		set @where_clause = ' WHERE um.IsActive = 1 AND dl.IsActive = 1  AND dl.TenantId = '+cast(@tenant_id as varchar)+' AND um.TenantId = '+cast(@tenant_id as varchar);
		if(@filter_col is not null and @filter_by is not null)  
		begin
			if(@filter_col = 'RoleId')
			begin
				set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			end
			else if(@filter_col = 'DealerId')
			begin
				set @where_clause = @where_clause + ' AND '+ +cast(@filter_by as varchar) + ' = (' +@filter_col + ' & '+cast(@filter_by as varchar)+')';
			end
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND um.UserName like ''%'+@search_term+'%''';
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactList AS (SELECT ROW_NUMBER() OVER(ORDER BY um.UserId DESC) AS RowNumber ,um.*,dl.DealerName as DealerName FROM User_Master um inner join Dealer dl on um.DealerId = dl.DealerId ' + @where_clause + ') SELECT * FROM All_ContactList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		end
	else
		set @total_records = 0;
END









GO
/****** Object:  StoredProcedure [dbo].[SP_Get_User_MsterList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_User_MsterList] @tenant_id int, @page_no int, @records_per_page int, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		select @total_records = COUNT(*) FROM User_Master where IsActive = 1 and TenantId = @tenant_id;
		WITH All_Users AS
		(
			SELECT ROW_NUMBER() OVER(ORDER BY UserId ASC) AS RowNumber,UM.* FROM User_Master UM  
		) SELECT * FROM All_Users WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
	end
	else
		set @total_records = 0;
END









GO
/****** Object:  StoredProcedure [dbo].[SP_Get_UserList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Get_UserList] @tenant_id int, @page_no int, @records_per_page int, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		select @total_records = COUNT(*) FROM UserMaster where IsActive = 1 and TenantId = @tenant_id;
		WITH All_Users AS
		(
			SELECT ROW_NUMBER() OVER(ORDER BY UserId ASC) AS RowNumber,UM.* FROM UserMaster UM  
			where UM.IsActive = 1 and  UM.TenantId = @tenant_id 
		) SELECT * FROM All_Users WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
	end
	else
		set @total_records = 0;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetActiveCampaignbyDealerid]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetActiveCampaignbyDealerid] 
@State bit , 
@DealerId int
as 
begin
Select CampaignId from CampaignExtraDetails c
inner join Dealer d on c.DealerId=d.DealerId
where c.IsActive=@State and c.DealerId=@DealerId
and d.IsActive=1
end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetActiveCampaignbyDealeridInActive]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetActiveCampaignbyDealeridInActive] 
@State bit , 
@DealerId int
as 
begin
Select CampaignId from CampaignExtraDetails c
where c.IsActive=@State and c.DealerId=@DealerId
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetActiveContactListbyCampaignId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetActiveContactListbyCampaignId] 
@IsActive bit , 
@CampaignId int
as 
begin
Select CampaignList_Id from CampaignContact_List ccl 
inner join Contact_List cl on ccl.ListId=cl.Id
inner join Dealer d on cl.DealerId= d.DealerId
where ccl.IsActive=@IsActive and CampaignId=@CampaignId
and d.IsActive=1
end









GO
/****** Object:  StoredProcedure [dbo].[SP_GetActiveSessions]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetActiveSessions] @tenant_id int as begin

	select * from UniCampaignSession where TenantId = @tenant_id and EndDateTime is null

end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetAgentByAgentId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_GetAgentByAgentId] @Id int as begin
select * from UCCEAgent where PeripheralNumber=@Id
END








GO
/****** Object:  StoredProcedure [dbo].[SP_GetAgentScriptBodyDetails]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAgentScriptBodyDetails]
(
@CampaignName varchar(200)
)
as
begin

select ScriptBody from CampaignExtraDetails ced inner join AgentScripts ass on ced.AgentScriptID=ass.AgentScriptID
where Name=@CampaignName

end


GO
/****** Object:  StoredProcedure [dbo].[SP_GetAllAgents]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAllAgents] as
begin

Select * from [dbo].[UCCEAgent]
end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetAllDealers]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAllDealers] @IsActive bit = null   as 
begin
If(@IsActive is null)
 begin
Select * from Dealer 
end
else
Select * from Dealer where IsActive=@IsActive
end









GO
/****** Object:  StoredProcedure [dbo].[SP_GetAllDNCRule]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAllDNCRule] as
begin

Select * from [dbo].[DNCRule]
end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetAllRoles]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAllRoles] @IsActive bit = null   as 
begin
If(@IsActive is null)
 begin
Select * from Role_Master 
end
else
Select * from Role_Master where IsActive=@IsActive
end









GO
/****** Object:  StoredProcedure [dbo].[SP_GetAllTenants]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAllTenants] @IsActive bit = null   as 
begin
If(@IsActive is null)
 begin
Select * from Tenants 
end
else
Select * from Tenants where IsActive=@IsActive
end















GO
/****** Object:  StoredProcedure [dbo].[SP_GetAreaCodes]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetAreaCodes]
AS
BEGIN
    SET NOCOUNT ON;

    SELECT AreaCode
    FROM AreaCode_list;
END;


GO
/****** Object:  StoredProcedure [dbo].[SP_GetAttemptByMapId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAttemptByMapId] @mapId int
as begin
	 select max(CampaignList_Id) as AttemptId from ContactList_ImportStatus where ListId=@mapId
end









GO
/****** Object:  StoredProcedure [dbo].[SP_GetAudit_Trail]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetAudit_Trail] @tenant_id int, @start_date datetime, @end_date datetime, @page_no int, @records_per_page int, @sort_by nvarchar(50) = 'DateTime' ,@direction nvarchar(4)='DESC', @total_records int output as
begin
select @total_records = COUNT(*) FROM Audit_Trail trail inner join User_Master um on   um.UserId = trail.UserId where trail.TenantId = @tenant_id and um.TenantId = @tenant_id and (DateTime between @start_date and @end_date);
declare @query nvarchar(max)
set @query = '
		WITH Trail AS(
			SELECT ROW_NUMBER() OVER(ORDER BY DateTime '+@direction+') AS RowNumber ,trail.*, um.UserName,d.DealerName FROM Audit_Trail trail 
				inner join User_Master um on um.UserId = trail.UserId
				inner join Dealer d on um.DealerId = d.DealerId 
			WHERE trail.TenantId = '+CONVERT(varchar,@tenant_id)+' and DateTime BETWEEN '''+convert(varchar,@start_date,121) +''' and '''+convert(varchar,@end_date,121)+''') SELECT * FROM Trail WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+ @sort_by + ' '+@direction
exec(@query)
end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetAuditTrail]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[SP_GetAuditTrail] @tenant_id int, @start_date datetime, @end_date datetime, @page_no int, @records_per_page int, @sort_by nvarchar(50) = 'DateTime' ,@direction nvarchar(4)='DESC', @total_records int output as
begin
select @total_records = COUNT(*) FROM Audit_Trail trail inner join UserMaster um on   um.UserId = trail.UserId where trail.TenantId = @tenant_id and um.TenantId = @tenant_id and (DateTime between @start_date and @end_date);
declare @query nvarchar(max)
set @query = 'WITH Trail AS(SELECT ROW_NUMBER() OVER(ORDER BY DateTime '+@direction+') AS RowNumber ,trail.*, um.Username FROM Audit_Trail trail inner join UserMaster um on um.UserId = trail.UserId WHERE trail.TenantId = '+CONVERT(varchar,@tenant_id)+' and DateTime BETWEEN '''+convert(varchar,@start_date,121) +''' and '''+convert(varchar,@end_date,121)+''') SELECT * FROM Trail WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+ @sort_by + ' '+@direction
exec(@query)
end

















GO
/****** Object:  StoredProcedure [dbo].[SP_GetBulkCallbackById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetBulkCallbackById] @bulk_id int as 
begin
select * from BulkCallback where BulkId = @bulk_id
end















GO
/****** Object:  StoredProcedure [dbo].[SP_GetByEmailId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetByEmailId]
	@email_id int
	as 
	begin 
	Select * from EmailSend where EmailId=@email_id
	end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetCallDetails]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetCallDetails] @campaignId int,@import_id int, @page_no int, @records_per_page int, @total_records int output as 
begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM Call_Result_Table_'+ cast(@campaignId as varchar) +' CR ';
		set @where_clause = ' WHERE CR.ImportList_Id = '+cast(@import_id as varchar)+ ' AND CR.WrapupData is not null ';
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_WrapupData AS(SELECT ROW_NUMBER() OVER(ORDER BY CR.ImportList_Id DESC) AS RowNumber ,CR.* FROM Call_Result_Table_'+ cast(@campaignId as varchar) +' CR ' + @where_clause + ') SELECT *  FROM All_WrapupData WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetCallsAttemptedByDate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_GetCallsAttemptedByDate] 
	@tenant_id int,
	@campaign_id int,
	@ListId int,
	@start_date_utc datetime,
	@end_date_utc datetime
as begin
	declare @sql nvarchar(MAX);
	set @sql = 'SELECT	CR.RecordId,IL.ImportList_Id as Identifier,CR.Phone as PhoneAttempted, IL.AccountNumber,
						IL.FirstName,IL.LastName,IL.ExtraData, CR.CallResult,IL.Phone01,IL.Phone02,IL.Phone03,IL.Phone04,IL.Phone05,
						IL.Phone06,IL.Phone07,IL.Phone08,IL.Phone09,IL.Phone10,IL.Status as ImportStatus,IL.ImportDateTime,IL.MapId,
						IL.AttemptId,CR.CallDateTime,OCD.DateTime as CallDateTimeLocal,OCD.WrapupData,OCD.CallGUID,OCD.AgentSkillGroupID as AgentId
						FROM [dbo].[Call_Result_Table_'+cast(@campaign_id as nvarchar)+'] CR 
						INNER JOIN [dbo].[Import_List_Table_'+cast(@campaign_id as nvarchar)+'] IL ON CR.ImportList_Id = IL.ImportList_Id 
						INNER JOIN [dbo].[Outbound_Call_Detail_'+cast(@tenant_id as nvarchar)+'] OCD ON CR.DialerRecoveryKey = OCD.RecoveryKey 
						WHERE (CR.CallDateTime between @start_date_utc AND @end_date_utc) 
						
						AND (IL.MapId IN (SELECT DISTINCT MapId FROM ContactList_ImportStatus WHERE ListId = @ListId))
				';
				select @sql;
	execute sp_executesql @sql, N'@campaign_id int,@ListId int,@start_date_utc datetime,@end_date_utc datetime', @campaign_id, @ListId,@start_date_utc,@end_date_utc ;
end





GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaign_Lists_ReportByDate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaign_Lists_ReportByDate] 
	@tenant_id int,
	@campaign_id int,
	@sequence_id int,
	@start_date_utc datetime,
	@end_date_utc datetime
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (
					SELECT 
						ST.CampaignList_Id AS AttemptId,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS DateTime,
						IT.AutogeneratedFileName AS FileName, 
						ST.TotalRecords AS TotalRecordsInFile, 
						ST.TotalRecordImported AS RecordsImportedToCampaign,
						ST.TotalInvalid as InvalidRecordsInFile,
						ST.TotalDncFiltered as RecordsExcludedFromCampaign,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
						COUNT(IIF(CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc,1,NULL)) as DialAttemptsMadeToday,
						COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ) AND (CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10) AND (CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_'+CAST(@tenant_id AS nvarchar)+' CR
						INNER JOIN Import_List_'+CAST(@tenant_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.MapId = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
					WHERE IL.CampaignId = @campaign_id AND IT.SequenceId = @sequence_id
					GROUP BY IT.CreatedOn, ST.CampaignList_Id,IT.AutogeneratedFileName,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered
				) 
					SELECT 
						IR.DateTime, 
						IR.FileName, 
						IR.TotalRecordsInFile, 
						IR.RecordsImportedToCampaign,
						IR.InvalidRecordsInFile,
						IR.RecordsExcludedFromCampaign,
						IR.DialAttemptsMadeToday,
						IR.CallsAttemptedToday,
						(DialAttemptsMadeToday - CallsAttemptedToday) as FailedDialAttemptsToday,
						IR.SuccessfulCallsMadeToday,
						(CallsAttemptedToday - SuccessfulCallsMadeToday) as UnSuccessfulCallAttemptsToday,
						IR.TotalDialAttemptsMade,
						IR.TotalCallsAttempted,
						(TotalDialAttemptsMade - TotalCallsAttempted) as TotalFailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						RecordsWithNoDialAttempts = (SELECT COUNT(1) FROM Import_List_1000 WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						RecordsWithNoCallAttempts = (SELECT COUNT(1) FROM Import_List_1000 WHERE AttemptId = IR.AttemptId AND Status IN(12,9) AND AttemptsMade = 0)
					FROM IR ORDER BY IR.DateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int,@sequence_id int,@start_date_utc datetime,@end_date_utc datetime', @campaign_id, @sequence_id,@start_date_utc,@end_date_utc ;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignAssignedLists_ReportByDate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignAssignedLists_ReportByDate] 
	@campaign_id int,
	@start_date_utc datetime,
	@end_date_utc datetime
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
			
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS Uploaded,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
						COUNT(IIF(CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc,1,NULL)) as DialAttemptsMadeToday,
						COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ) AND (CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10) AND (CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR						
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id

					
					   GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered

) 
					SELECT 
					    CampaignName = (SELECT Name FROM CampaignExtraDetails  WHERE CampaignId = '+CAST(@campaign_id AS nvarchar)+'),
						IR.AssignDateTime, 
						IR.CallingList, 
						IR.TotalRecords, 
						IR.Uploaded,
						IR.InvalidRecords,
						IR.RecordsExcluded,
						(TotalDialAttemptsMade - TotalCallsAttempted) as FailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						Pending_To_Dialed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9,11) AND DialAttempts > 0)
					FROM IR ORDER BY IR.AssignDateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int,@start_date_utc datetime,@end_date_utc datetime', @campaign_id,@start_date_utc,@end_date_utc ;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignAssignedListsReportByDate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignAssignedListsReportByDate] 
	@campaign_id int,
	@start_date_utc datetime,
	@end_date_utc datetime
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as ContactListName,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
			
						ST.TotalRecords AS TotalRecordsInList, 
						ST.TotalRecordImported AS RecordsImportedToCampaign,
						ST.TotalInvalid as InvalidRecordsInFile,
						ST.TotalDncFiltered as RecordsExcludedFromCampaign,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
						COUNT(IIF(CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc,1,NULL)) as DialAttemptsMadeToday,
						COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ) AND (CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10) AND (CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
					
					GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered

) 
					SELECT 
						IR.AssignDateTime, 
						IR.ContactListName, 
						IR.TotalRecordsInList, 
						IR.RecordsImportedToCampaign,
						IR.InvalidRecordsInFile,
						IR.RecordsExcludedFromCampaign,
						IR.DialAttemptsMadeToday,
						IR.CallsAttemptedToday,
						(DialAttemptsMadeToday - CallsAttemptedToday) as FailedDialAttemptsToday,
						IR.SuccessfulCallsMadeToday,
						(CallsAttemptedToday - SuccessfulCallsMadeToday) as UnSuccessfulCallAttemptsToday,
						IR.TotalDialAttemptsMade,
						IR.TotalCallsAttempted,
						(TotalDialAttemptsMade - TotalCallsAttempted) as TotalFailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						RecordsWithNoDialAttempts = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						RecordsWithNoCallAttempts = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9) AND AttemptsMade = 0)
					FROM IR ORDER BY IR.AssignDateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int,@start_date_utc datetime,@end_date_utc datetime', @campaign_id,@start_date_utc,@end_date_utc ;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignAssignedListsReportByDate1]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignAssignedListsReportByDate1] 
	@campaign_id int,
	@start_date_utc datetime,
	@end_date_utc datetime
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as ContactListName,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
			
						ST.TotalRecords AS TotalRecordsInList, 
						ST.TotalRecordImported AS RecordsImportedToCampaign,
						ST.TotalInvalid as InvalidRecordsInFile,
						ST.TotalDncFiltered as RecordsExcludedFromCampaign,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
						COUNT(IIF(CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc,1,NULL)) as DialAttemptsMadeToday,
						COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ) AND (CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10) AND (CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
					WHERE (CR.CallDateTime between @start_date_utc AND @end_date_utc)
					GROUP BY IT.CreatedOn,CL.Name, ST.ListId ,ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered

) 
					SELECT 
						IR.AssignDateTime, 
						IR.ContactListName, 
						IR.TotalRecordsInList, 
						IR.RecordsImportedToCampaign,
						IR.InvalidRecordsInFile,
						IR.RecordsExcludedFromCampaign,
						IR.DialAttemptsMadeToday,
						IR.CallsAttemptedToday,
						(DialAttemptsMadeToday - CallsAttemptedToday) as FailedDialAttemptsToday,
						IR.SuccessfulCallsMadeToday,
						(CallsAttemptedToday - SuccessfulCallsMadeToday) as UnSuccessfulCallAttemptsToday,
						IR.TotalDialAttemptsMade,
						IR.TotalCallsAttempted,
						(TotalDialAttemptsMade - TotalCallsAttempted) as TotalFailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						RecordsWithNoDialAttempts = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						RecordsWithNoCallAttempts = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9) AND AttemptsMade = 0)
					FROM IR ORDER BY IR.AssignDateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int,@start_date_utc datetime,@end_date_utc datetime', @campaign_id,@start_date_utc,@end_date_utc ;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignAssignedListsReportByDate2]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignAssignedListsReportByDate2] 
	@campaign_id int,
	@start_date_utc datetime,
	@end_date_utc datetime
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
			
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS UploadedRecords,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
						COUNT(IIF(CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc,1,NULL)) as DialAttemptsMadeToday,
						COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ) AND (CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10) AND (CR.CallDateTime BETWEEN @start_date_utc and @end_date_utc),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
					WHERE (CR.CallDateTime between @start_date_utc AND @end_date_utc)
					GROUP BY IT.CreatedOn,CL.Name, ST.ListId ,ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered

) 
					SELECT 
						IR.AssignDateTime, 
						IR.CallingList, 
						IR.TotalRecords, 
						IR.UploadedRecords,
						IR.InvalidRecords,
						IR.RecordsExcluded,
				
						IR.TotalCallsAttempted,
						(TotalDialAttemptsMade - TotalCallsAttempted) as TotalFailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						PendingContacts = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0)
						
					FROM IR ORDER BY IR.AssignDateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int,@start_date_utc datetime,@end_date_utc datetime', @campaign_id,@start_date_utc,@end_date_utc ;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignAssignListReportByDate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignAssignListReportByDate] 
	@tenant_id int,
	@campaign_id int,
	@sequence_id int,
	@start_date_utc datetime,
	@end_date_utc datetime
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (
					SELECT 
						ST.CampaignList_Id AS AttemptId,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS DateTime,
						IT.AutogeneratedFileName AS FileName, 
						ST.TotalRecords AS TotalRecordsInFile, 
						ST.TotalRecordImported AS RecordsImportedToCampaign,
						ST.TotalInvalid as InvalidRecordsInFile,
						ST.TotalDncFiltered as RecordsExcludedFromCampaign,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
						COUNT(IIF(CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc,1,NULL)) as DialAttemptsMadeToday,
						COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ) AND (CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10) AND (CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_'+CAST(@tenant_id AS nvarchar)+' CR
						INNER JOIN Import_List_'+CAST(@tenant_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.MapId = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
					WHERE IL.CampaignId = @campaign_id AND IT.SequenceId = @sequence_id
					GROUP BY IT.CreatedOn, ST.CampaignList_Id,IT.AutogeneratedFileName,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered
				) 
					SELECT 
						IR.DateTime, 
						IR.FileName, 
						IR.TotalRecordsInFile, 
						IR.RecordsImportedToCampaign,
						IR.InvalidRecordsInFile,
						IR.RecordsExcludedFromCampaign,
						IR.DialAttemptsMadeToday,
						IR.CallsAttemptedToday,
						(DialAttemptsMadeToday - CallsAttemptedToday) as FailedDialAttemptsToday,
						IR.SuccessfulCallsMadeToday,
						(CallsAttemptedToday - SuccessfulCallsMadeToday) as UnSuccessfulCallAttemptsToday,
						IR.TotalDialAttemptsMade,
						IR.TotalCallsAttempted,
						(TotalDialAttemptsMade - TotalCallsAttempted) as TotalFailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						RecordsWithNoDialAttempts = (SELECT COUNT(1) FROM Import_List_1000 WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						RecordsWithNoCallAttempts = (SELECT COUNT(1) FROM Import_List_1000 WHERE AttemptId = IR.AttemptId AND Status IN(12,9) AND AttemptsMade = 0)
					FROM IR ORDER BY IR.DateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int,@sequence_id int,@start_date_utc datetime,@end_date_utc datetime', @campaign_id, @sequence_id,@start_date_utc,@end_date_utc ;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignDailedCountByAttemptNumber]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignDailedCountByAttemptNumber]
	@campaign_id int ,
	@attempt_number int 
AS BEGIN
	DECLARE @sql nvarchar(MAX);

    SET @sql = 'SELECT COUNT(IIF(IL.Status IN(12,9) AND IL.ImportAttempts= '+CAST(@attempt_number AS nvarchar(100))+ 'AND IL.DialAttempts=' +CAST(@attempt_number AS nvarchar(100)) +',1,NULL)) 
	FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar(100))+ ' AS IL  
	INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
	INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
	INNER Join Contact_List CL 
	on IT.ListId=CL.Id where CL.IsActive=1';

	execute sp_executesql @sql, N'@campaign_id INT ',N'@attempt_number INT ', @campaign_id, @attempt_number;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignDailedCountByAttemptNumbers]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignDailedCountByAttemptNumbers] 
	@campaign_id int ,
	@attempt_number int 
AS BEGIN
	DECLARE @sql nvarchar(MAX);

    SET @sql = 'SELECT COUNT(IIF(IL.Status IN(12,9) AND IL.ImportAttempts= '+CAST(@attempt_number AS nvarchar(100))+ 'AND IL.DialAttempts>0 OR IL.DialAttempts>' +CAST(@attempt_number AS nvarchar(100)) +',1,NULL)) as Dailed
	FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar(100))+ ' AS IL  
	INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
	INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
	INNER Join Contact_List CL 
	on IT.ListId=CL.Id where CL.IsActive=1';

	execute  (@sql)
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignDataForEmail]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignDataForEmail]
    @CampaignId INT
AS
BEGIN
   -- Get the column names as a single row without quotes and semicolons
    DECLARE @ColumnNames NVARCHAR(MAX);
    SELECT @ColumnNames = STUFF((
        SELECT ',' + REPLACE(QUOTENAME(COLUMN_NAME), '"', '')
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = 'Outbound_Call_Detail_1000'
        AND COLUMN_NAME IN ('Id','RecoveryKey', 'DateTime', 'DateTimeUtc', 'CampaignID', 'CallResult', 'Phone', 'AccountNumber', 'FirstName', 'LastName', 'CallbackDateTime', 'WrapupData', 'CallGUID', 'AgentSkillGroupID', 'AgentName', 'AgentLoginName', 'AgentId', 'SkillGroupSkillTargetID','Status')
        ORDER BY ORDINAL_POSITION
        FOR XML PATH('')
    ), 1, 1, '');

    -- Get the data rows
    SELECT Id,RecoveryKey, DateTime, DateTimeUtc, CampaignID, CallResult, Phone, AccountNumber, FirstName, LastName, 
           CallbackDateTime, WrapupData, CallGUID, AgentSkillGroupID, AgentName, AgentLoginName, AgentId, SkillGroupSkillTargetID,Status
    FROM Outbound_Call_Detail_1000
    WHERE CampaignId = @CampaignId
END


GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignDetails]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetCampaignDetails] 
	@tenant_id int,
	@campaign_id int
as begin
	select * from CampaignExtraDetails c
	inner join  Dealer d on c.DealerId=d.DealerId
	inner join Schedule_Mail sm on c.CampaignId=sm.CampaignId
	where c.TenantId = @tenant_id and c.CampaignId = @campaign_id and c.IsActive=1
	and d.IsActive=1
end


GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignGroups]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetCampaignGroups] @tenant_id int,@DealerId int=null,  @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output as   
begin  
 if(dbo.TenantState(@tenant_id) = 1)  
 begin  
  declare @count_query nvarchar(max);  
  declare @main_query nvarchar(max);  
  declare @where_clause nvarchar(max);  
   
  set @count_query = 'select @total_records = COUNT(1) FROM CampaignGroupMaster h';  
  set @where_clause = ' WHERE h.IsActive = 1 and h.TenantId = '+cast(@tenant_id as varchar)+' ';  
  set @where_clause = @where_clause;  
  if(@DealerId != 0)    
  begin  
   set @where_clause = @where_clause +'and (h.DepartmentId = '+cast(@DealerId as varchar)+' or h.DepartmentId=-1)';  
  end  
    
  if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))    
  begin  
   set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);  
  end  

  if(@filter_col is not null and @filter_by is not null and (@filter_col = 'GroupId'))    
  begin  
   set @where_clause = @where_clause +' AND '+@filter_col + ' = '+ cast(@filter_by as varchar);  
  end  
  
  if(@search_term is not null)  
  begin  
   set @where_clause = @where_clause + ' AND h.Name like ''%'+@search_term+'%''';  
  end  
  
  set @count_query = @count_query + @where_clause;  
  execute sp_executesql @count_query, N'@total_records int output',@total_records output;  
  set @main_query = 'WITH All_CamapignGroups AS(SELECT ROW_NUMBER() OVER(ORDER BY h.Id DESC) AS RowNumber ,h.* FROM CampaignGroupMaster h  ' + @where_clause + ') SELECT *  FROM All_CamapignGroups WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';  
  exec(@main_query);  
  --select(@main_query);  
  print(@main_query);  
 end  
 else  
  set @total_records = 0;  
end  


GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignIdBySkill]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_GetCampaignIdBySkill] @SkillQuerys  nvarchar(max)as 
begin

declare @where_clause nvarchar(max)
declare @mainQuery nvarchar(max)
declare @query nvarchar(max)

set @query='select distinct sm.PreviewCampaignId as PreviewCampaignId  from [dbo].[SkillGroupMap] sm inner join [dbo].[PreviewCampaign] pc on sm.PreviewCampaignId=pc.PreviewCampaignId where pc.IsActive=1 and pc.StartDate<getdate() and pc.EndDate>getDate() and pc.StartTime<Convert(Time,getDate()) and pc.EndTime >Convert(Time,getDate()) ';

set @where_clause=' and ('+ @SkillQuerys +')';

 set @mainQuery=@query + @where_clause;

 exec(@mainQuery);

end







GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeCount]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeCount] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT
                        COUNT(IIF(IL.Status IN(2,4,9,12),1,NULL)) as Total,
						COUNT(IIF(IL.Status IN(2,4,12) AND (AttemptsMade>0 OR AttemptsMade>0),1,NULL)) as Pending,
						COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dailed,     
						COUNT(IIF(IL.Status IN(12,9) AND CallResult=9,1,NULL)) as Busy,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL  
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeCount_Correct]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeCount_Correct]
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT 
			            CampaignID=@campaign_id,
						Total=(SELECT COUNT(ImportList_Id) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9)),
						Pending = (SELECT COUNT(ImportList_Id) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' Status IN(9) and ImportAttempts = 1 and AttemptsMade = 0),
						Dailed = (SELECT COUNT(ImportList_Id) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12) and ImportAttempts = 1 and AttemptsMade >0),
						Busy = (SELECT COUNT(ImportList_Id) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND CallResult=9),
						Closed = (SELECT COUNT(ImportList_Id) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status = 12 OR (callresult = 10 and status = 9)';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeCount_New]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeCount_New] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT 
			            CampaignID=@campaign_id,
						Total=(SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9)),
						Pending = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status=9 and ImportAttempts = 1 and AttemptsMade = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status=12 and ImportAttempts = 1 and AttemptsMade >0),
						Busy = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12,9) AND CallResult=9),
						Closed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status = 12 OR (callresult = 10 and status = 9))';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeCount_Test]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeCount_Test]
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT 
			            CampaignName = (SELECT Name FROM CampaignExtraDetails  WHERE CampaignId = '+CAST(@campaign_id AS nvarchar)+'),
						Total=(SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9)),
						Pending = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(9) AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12) AND DialAttempts > 0),
						Busy = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12,9) AND CallResult=9),
						Closed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12,9) AND CallResult=10)';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeCountDashboard]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeCountDashboard] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT
                        COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL)) as Total,
						--COUNT(IIF(IL.Status IN(2,4,9) AND (AttemptsMade = 0 OR AttemptsMade>0),1,NULL)) as Pending,
						COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dialed,
						COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Pending,
						--COUNT(IIF(IL.Status IN(12,9) AND CallResult=9,1,NULL)) as Busy,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						--COUNT(IIF(IL.Status IN(12) AND CallResult IN(16,20,21),1,NULL)) as TotalAbandoned
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL  
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeCountDashboardUpdated]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeCountDashboardUpdated] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT
                        COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL)) as Total,
						ISNULL(SUM(DialAttempts),0) as Dialed,
						--COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dialed,
						(COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
						--COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Pending,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
						COUNT(IIF(IL.Status IN(3,4,6),1,NULL)) as Exclusion
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL  
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeCountDashboardUpdated_New]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeCountDashboardUpdated_New] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT
                        COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL)) as Total,
						ISNULL(SUM(DialAttempts),0) as Dialed,
						--COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dialed,
						(COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
						--COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Pending,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
						COUNT(IIF(IL.Status IN(3,4,6),1,NULL)) as Exclusion
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL  
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1 and IL.CreatedOn = cast(getdate() as Date)';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END


GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeStatus_ListWise]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeStatus_ListWise] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS Uploaded,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
                        COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR						
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
					    GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered) 
					
					SELECT 
					    CampaignName = (SELECT Name FROM CampaignExtraDetails  WHERE CampaignId = '+CAST(@campaign_id AS nvarchar)+'),
						IR.AssignDateTime, 
						IR.CallingList, 
						IR.TotalRecords, 
						IR.Uploaded,
						IR.InvalidRecords,
						IR.RecordsExcluded,
						(TotalDialAttemptsMade - TotalCallsAttempted) as FailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						Pending_To_Dialed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9,11) AND DialAttempts > 0),
						ListWise_Total = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId),
						ListWise_Pending = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						ListWise_Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12) AND DialAttempts > 0),
						ListWise_Busy = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND CallResult=9),
						ListWise_Closed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9) AND CallResult=10)
					FROM IR ORDER BY IR.AssignDateTime DESC';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCount]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCount]
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = 'SELECT   
						ST.CampaignList_Id AS CallingListID,
						CL.Name as CallingList,
						COUNT(IIF(IL.Status IN(2,4,9,12),1,NULL)) as Total,
						COUNT(IIF(IL.Status IN(2,4,9) AND (AttemptsMade = 0 OR AttemptsMade>0),1,NULL)) as Pending,
						COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dailed,
						COUNT(IIF(IL.Status IN(12,9) AND CallResult=9,1,NULL)) as Busy,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL 
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1
						GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id
					    ORDER BY CallingListID DESC';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCount_New]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCount_New] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				SELECT   
						ST.CampaignList_Id AS CallingListID,
						CL.Name as CallingList,
						COUNT(IIF(IL.Status IN(12,9),1,NULL)) as Total,
						COUNT(IIF(IL.Status=9 AND ImportAttempts = 1 and AttemptsMade = 0,1,NULL)) as Pending,
						COUNT(IIF(IL.Status=12 AND ImportAttempts = 1 and AttemptsMade >0,1,NULL)) as Dailed,
						COUNT(IIF(IL.Status IN(12,9) AND CallResult=9,1,NULL)) as Busy,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.status = 9),1,NULL)) as Closed
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL 
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
						GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id
					    ORDER BY CallingListID DESC';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCount_OLD]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCount_OLD]  
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS Uploaded,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
                                                COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR						
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
					    GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered) 
					
					SELECT 
					    CampaignName = (SELECT Name FROM CampaignExtraDetails  WHERE CampaignId = '+CAST(@campaign_id AS nvarchar)+'),
						IR.AssignDateTime, 
						IR.CallingList as CallingList,
						IR.AttemptId as CallingListID,
						Total = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId),
						Pending = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12) AND DialAttempts > 0),
						Busy = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND CallResult=9),
						Closed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9) AND CallResult=10)
					FROM IR ORDER BY IR.AssignDateTime DESC';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCount_PK]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCount_PK]--6079--, 1, 4
	@campaign_id int,
	@pageNumber int = null ,
	@rows int = null
	
	
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS Uploaded,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
                        COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR						
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
					    GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered) 
					
					SELECT 
					    CampaignName = (SELECT Name FROM CampaignExtraDetails  WHERE CampaignId = '+CAST(@campaign_id AS nvarchar)+'),
						IR.AssignDateTime, 
						IR.CallingList as CallingList,
						IR.AttemptId as CallingListID,
						Total = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId),
						Pending = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12) AND DialAttempts > 0),
						Busy = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND CallResult=9),
						Closed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9) AND CallResult=10)
					FROM IR ORDER BY IR.AssignDateTime DESC';

    create table #temp(CampaignName nvarchar(30), AssignDateTime datetime, 	CallingList nvarchar(max), CallingListID int,
				     	Total int,	Pending int,	Dailed int, 	Busy int,	Closed int)
	
	insert into #temp (CampaignName,	AssignDateTime,	CallingList,	CallingListID,	Total,	Pending,Dailed,	Busy, Closed)
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;

	if @pageNumber is null or  @rows is null
	begin
		select CampaignName,	AssignDateTime,	CallingList,	CallingListID,	Total,	Pending,Dailed,	Busy, Closed from  #temp
		order by AssignDateTime desc
	end
	else
	begin
		select CampaignName,	AssignDateTime,	CallingList,	CallingListID,	Total,	Pending,Dailed,	Busy, Closed from  #temp
		order by AssignDateTime desc
		OFFSET (@rows * (@pageNumber -1)) ROWS FETCH NEXT @rows  ROWS ONLY;
	end

	drop table #temp;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCountDashboard]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCountDashboard]
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = 'SELECT   
						ST.CampaignList_Id AS CallingListID,
						CL.Name as CallingList,
						COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL)) as Total,
						--COUNT(IIF(IL.Status IN(2,4,9) AND (AttemptsMade = 0 OR AttemptsMade>0),1,NULL)) as Pending,
						COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dialed,
						COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Pending,
						--COUNT(IIF(IL.Status IN(12,9) AND CallResult=9,1,NULL)) as Busy,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						--COUNT(IIF(IL.Status IN(12) AND CallResult IN(16,20,21),1,NULL)) as TotalAbandoned
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL 
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1
						GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id
					    ORDER BY CallingListID DESC';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCountDashboardUpdated]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCountDashboardUpdated]
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = 'SELECT   
						ST.CampaignList_Id AS CallingListID,
						CL.Name as CallingList,
						COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL)) as Total,
						ISNULL(SUM(DialAttempts),0) as Dialed,
						---COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dialed,
						(COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
						--COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Pending,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
						COUNT(IIF(IL.Status IN(3,4,6),1,NULL)) as Exclusion
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL 
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1
						GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id
					    ORDER BY CallingListID DESC';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCountTest]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRealTimeStatus_ListWiseCountTest] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				SELECT   
						ST.CampaignList_Id AS CallingListID,
						CL.Name as CallingList,
						COUNT(IIF(IL.Status IN(12,9),1,NULL)) as Total,
						COUNT(IIF(IL.Status IN(9) AND DialAttempts = 0,1,NULL)) as Pending,
						COUNT(IIF(IL.Status IN(12) AND DialAttempts>0,1,NULL)) as Dailed,
						COUNT(IIF(IL.Status IN(12,9) AND CallResult=9,1,NULL)) as Busy,
						COUNT(IIF(IL.Status IN(12,9) AND CallResult=10,1,NULL)) as Closed
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL 
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
						GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id
					    ORDER BY CallingListID DESC';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRecordStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignRecordStatus] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS Uploaded,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
                        COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR						
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
					    GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered

) 
					SELECT 
						isnull(SUM(IR.TotalRecords),0) TotalRecords , 
						isnull(SUM(IR.InvalidRecords),0) InvalidRecords,
						isnull(SUM(IR.RecordsExcluded),0) RecordsExcluded,
						isnull(SUM((TotalDialAttemptsMade - TotalCallsAttempted)),0) as FailedDialAttempts,
						isnull(SUM(IR.TotalSuccessfulCallsMade),0)TotalSuccessfulCallsMade,
						isnull(SUM((TotalCallsAttempted - TotalSuccessfulCallsMade)),0) as TotalUnsuccessfulCallAttempts,
						UploadedRecords=(SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9)),
						Pending_To_Dialed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(9) AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12) AND DialAttempts > 0)
						FROM IR';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRecordStatus_Pramod]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignRecordStatus_Pramod]
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS Uploaded,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
                        COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR						
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id
					    GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered

) 
					SELECT 
						isnull(SUM(IR.TotalRecords),0) TotalRecords , 
						isnull(SUM(IR.InvalidRecords),0) InvalidRecords,
						isnull(SUM(IR.RecordsExcluded),0) RecordsExcluded,
						isnull(SUM((TotalDialAttemptsMade - TotalCallsAttempted)),0) as FailedDialAttempts,
						isnull(SUM(IR.TotalSuccessfulCallsMade),0)TotalSuccessfulCallsMade,
						isnull(SUM((TotalCallsAttempted - TotalSuccessfulCallsMade)),0) as TotalUnsuccessfulCallAttempts,
						UploadedRecords=(SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9)),
						Pending_To_Dialed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12,9) AND DialAttempts > 0)
						FROM IR';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRecordStatuskk]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignRecordStatuskk] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS 
				(

	
					SELECT 
						
						Total=(SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9)),
						Pending = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(9) AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12) AND DialAttempts > 0),
						Busy = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12,9) AND CallResult=9),
						Closed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12,9) AND CallResult=10)
						';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRecordStatuskkkk]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE PROCEDURE [dbo].[SP_GetCampaignRecordStatuskkkk] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT 
			            CampaignID=@campaign_id,
						Total=(SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9)),
						Pending = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(9) AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12) AND DialAttempts > 0),
						Busy = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12,9) AND CallResult=9),
						Closed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE  Status IN(12,9) AND CallResult=10)';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRecordStatusListWise]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCampaignRecordStatusListWise] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS Uploaded,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
                        COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR						
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id

					
					   GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered

) 
					SELECT 
					    CampaignName = (SELECT Name FROM CampaignExtraDetails  WHERE CampaignId = '+CAST(@campaign_id AS nvarchar)+'),
						IR.AssignDateTime, 
						IR.CallingList, 
						IR.TotalRecords, 
						IR.Uploaded,
						IR.InvalidRecords,
						IR.RecordsExcluded,
						(TotalDialAttemptsMade - TotalCallsAttempted) as FailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						Pending_To_Dialed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9,11) AND DialAttempts > 0)
					FROM IR ORDER BY IR.AssignDateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignRecordStatusNew]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[SP_GetCampaignRecordStatusNew] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (

				 select  ST.CampaignList_Id AS AttemptId,
						CL.Name as CallingList,
						ST.ListId AS MapId,
						DATEADD(SECOND,DATEDIFF(SECOND,GETDATE(),GETUTCDATE()),IT.CreatedOn) AS AssignDateTime,
						ST.TotalRecords AS TotalRecords, 
						ST.TotalRecordImported AS Uploaded,
						ST.TotalInvalid as InvalidRecords,
						ST.TotalDncFiltered as RecordsExcluded,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
                        COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR						
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id

					
					   GROUP BY IT.CreatedOn,CL.Name, ST.CampaignList_Id,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered

) 
					SELECT 
					    CampaignName = (SELECT Name FROM CampaignExtraDetails  WHERE CampaignId = '+CAST(@campaign_id AS nvarchar)+'),
						IR.AssignDateTime, 
						IR.CallingList, 
						IR.TotalRecords, 
						IR.Uploaded,
						IR.InvalidRecords,
						IR.RecordsExcluded,
						(TotalDialAttemptsMade - TotalCallsAttempted) as FailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						Pending_To_Dialed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						Dailed = (SELECT COUNT(1) FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' WHERE AttemptId = IR.AttemptId AND Status IN(12,9,11) AND DialAttempts > 0)
					FROM IR ORDER BY IR.AssignDateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignReportByDate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE  PROCEDURE [dbo].[SP_GetCampaignReportByDate] 

	@campaign_id int,
	@start_date_utc datetime,
	@end_date_utc datetime
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = '
				WITH IR AS (
					SELECT 
						ST.CampaignList_Id AS AttemptId,
						ST.ListId AS MapId,ct.Name AS ContactListName, 
						ST.TotalRecords AS TotalRecordsInFile, 
						ST.TotalRecordImported AS RecordsImportedToCampaign,
						ST.TotalInvalid as InvalidRecordsInFile,
						ST.TotalDncFiltered as RecordsExcludedFromCampaign,
						COUNT(1) AS TotalDialAttemptsMade,
						COUNT(IIF(CR.CallResult NOT IN (2, 17, 18, 19, 25, 26),1,NULL)) as TotalCallsAttempted, 
						COUNT(IIF(CR.CallResult = 10,1,NULL)) AS TotalSuccessfulCallsMade,
						COUNT(IIF(CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc,1,NULL)) as DialAttemptsMadeToday,
						COUNT(IIF((CR.CallResult NOT IN(2, 17, 18, 19, 25, 26) ) AND (CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc),1,NULL)) as CallsAttemptedToday,
						COUNT(IIF((CR.CallResult = 10) AND (CR.CallDateTime BETWEEN @start_date_utc AND @end_date_utc),1,NULL)) AS SuccessfulCallsMadeToday
						FROM Call_Result_Table_'+CAST(@campaign_id AS nvarchar)+' CR
						INNER JOIN Import_List_Table_'+CAST(@campaign_id AS nvarchar)+' IL ON CR.ImportList_Id = IL.ImportList_Id
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						Inner Join Contact_List ct on ct.Id=IT.ListId
					WHERE IL.CampaignId = @campaign_id
					GROUP BY IT.CreatedOn, ST.CampaignList_Id,IT.ContactListName,ST.TotalRecords,ST.ListId,ST.TotalRecordImported,ST.TotalInvalid,ST.TotalDncFiltered
				) 
					SELECT 
						
						IR.ContactListName, 
						IR.TotalRecordsInFile, 
						IR.RecordsImportedToCampaign,
						IR.InvalidRecordsInFile,
						IR.RecordsExcludedFromCampaign,
						IR.DialAttemptsMadeToday,
						IR.CallsAttemptedToday,
						(DialAttemptsMadeToday - CallsAttemptedToday) as FailedDialAttemptsToday,
						IR.SuccessfulCallsMadeToday,
						(CallsAttemptedToday - SuccessfulCallsMadeToday) as UnSuccessfulCallAttemptsToday,
						IR.TotalDialAttemptsMade,
						IR.TotalCallsAttempted,
						(TotalDialAttemptsMade - TotalCallsAttempted) as TotalFailedDialAttempts,
						IR.TotalSuccessfulCallsMade,
						(TotalCallsAttempted - TotalSuccessfulCallsMade) as TotalUnsuccessfulCallAttempts,
						RecordsWithNoDialAttempts = (SELECT COUNT(1) FROM Import_List_Tale'+CAST(@campaign_id AS nvarchar)+'  WHERE Status IN(12,9) AND  AttemptId = IR.AttemptId AND DialAttempts = 0),
						RecordsWithNoCallAttempts = (SELECT COUNT(1) FROM Import_List_Table'+CAST(@campaign_id AS nvarchar)+'  WHERE AttemptId = IR.AttemptId AND Status IN(12,9) AND AttemptsMade = 0)
					FROM IR ORDER BY IR.DateTime DESC
	';
	execute sp_executesql @sql, N'@campaign_id int,@start_date_utc datetime,@end_date_utc datetime', @campaign_id,@start_date_utc,@end_date_utc ;
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetCampaignState]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetCampaignState] @tenant_id int, @campaign_id int
as begin
	select * from CampaignState c
	inner join Dealer d on c.DealerId= d.DealerId	
	where c.TenantId = @tenant_id and CampaignId = @campaign_id and d.IsActive=1
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetCBMConfigByCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetCBMConfigByCampaign] @tenant_id int , @campaign_id int as
begin
	select * from CBMConfig where CampaignId = @campaign_id and TenantId = @tenant_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactList_ImportStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactList_ImportStatus] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @sort_col nvarchar(100) = null, @sort_direction nvarchar(10) = 'desc', @total_records int output
as begin
	
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM ContactList_ImportStatus';
		set @where_clause = ' WHERE dbo.CampaignListState(ListId) = 1';
		set @where_clause = @where_clause + ' AND ListId in (select CampaignList_Id from CampaignContact_List where TenantId =' +CAST(@tenant_id as varchar)+')';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'ListId' or @filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactList_ImportStatus AS (SELECT ROW_NUMBER() OVER(ORDER BY CampaignList_Id asc) AS RowNumber ,* FROM ContactList_ImportStatus ' + @where_clause + ') SELECT * FROM All_ContactList_ImportStatus WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';	
		if(@sort_col is not null and (@sort_col = 'LastAttemptedOn' or @sort_col = 'LastUpdatedOn' or @sort_col = 'CreatedOn'))
		begin
			set @main_query = @main_query + ' ORDER BY '+@sort_col + ' '+@sort_direction;
		end
		exec(@main_query)
	end
	else
		set @total_records = 0;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactList_ImportStatus_forUpdatetoProcess]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactList_ImportStatus_forUpdatetoProcess] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @sort_col nvarchar(100) = null, @sort_direction nvarchar(10) = 'desc', @total_records int output
as begin
	
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM ContactList_ImportStatus';
		set @where_clause = ' WHERE [TotalRecords]=[TotalRecordImported]+[TotalDncFiltered]+[TotalInvalid]+[TotalDuplicateFiltered] and dbo.CampaignListState(ListId) = 1';
		set @where_clause = @where_clause + ' AND ListId in (select CampaignList_Id from CampaignContact_List where TenantId =' +CAST(@tenant_id as varchar)+')';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'ListId' or @filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactList_ImportStatus AS (SELECT ROW_NUMBER() OVER(ORDER BY CampaignList_Id asc) AS RowNumber ,* FROM ContactList_ImportStatus ' + @where_clause + ') SELECT * FROM All_ContactList_ImportStatus WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';	
		if(@sort_col is not null and (@sort_col = 'LastAttemptedOn' or @sort_col = 'LastUpdatedOn' or @sort_col = 'CreatedOn'))
		begin
			set @main_query = @main_query + ' ORDER BY '+@sort_col + ' '+@sort_direction;
		end
		exec(@main_query)
	end
	else
		set @total_records = 0;
END





GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactList_ImportStatus_PreviewCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactList_ImportStatus_PreviewCampaign] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @sort_col nvarchar(100) = null, @sort_direction nvarchar(10) = 'desc', @total_records int output
as begin
	
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM PreviewImportStatus';
		set @where_clause = ' WHERE dbo.PreviewCampaignListState(ListId) = 1';
		set @where_clause = @where_clause + ' AND ListId in (select CampaignList_Id from PreviewCampaignContact_List where TenantId =' +CAST(@tenant_id as varchar)+')';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'ListId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactList_ImportStatus AS (SELECT ROW_NUMBER() OVER(ORDER BY CampaignList_Id DESC) AS RowNumber ,* FROM PreviewImportStatus ' + @where_clause + ') SELECT * FROM All_ContactList_ImportStatus WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';	
		if(@sort_col is not null and (@sort_col = 'LastAttemptedOn' or @sort_col = 'LastUpdatedOn' or @sort_col = 'CreatedOn'))
		begin
			set @main_query = @main_query + ' ORDER BY '+@sort_col + ' '+@sort_direction;
		end
	exec(@main_query)
	
	end
	else
		set @total_records = 0;
END








GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactListImportStatusById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactListImportStatusById] @id int
as begin
	select * from ContactList_ImportStatus  cis
	inner join CampaignContact_List ccl on cis.ListId=ccl.CampaignList_Id
	inner join Contact_List cl on ccl.ListId=cl.Id
	
	where cis.CampaignList_Id = @id and cl.IsActive=1
end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactListPreviewCampaignImportAttemptById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactListPreviewCampaignImportAttemptById] @id int
as begin
	select * from PreviewImportStatus where CampaignList_Id = @id
end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactListSequence]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactListSequence] 
	@sequence_id int
as begin
	select seq.*, src.Name as SourceName from ContactListSequence seq WITH (NOLOCK) inner join ImportList_Source src WITH (NOLOCK) on  seq.SourceId = src.Id where seq.Id = @sequence_id
end










GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactListSequenceIteration]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactListSequenceIteration] 
	@iteration_id int
as begin
	select iteration.*, list.Name as ContactListName, seq.Name as SequenceName from ContactListSequenceIteration iteration WITH (NOLOCK)
	inner join ContactListSequence seq WITH (NOLOCK) on seq.Id = iteration.SequenceId
	inner join Contact_List list WITH (NOLOCK) on list.Id = iteration.ListId
	where iteration.Id = @iteration_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactListSequenceIterationList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactListSequenceIterationList] 
	@tenant_id int, 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
	SET NOCOUNT ON;
   --     SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(*) FROM ContactListSequenceIteration iteration WITH (NOLOCK) inner join ContactListSequence seq WITH (NOLOCK) on seq.Id = iteration.SequenceId inner join Contact_List list WITH (NOLOCK) on iteration.ListId = list.Id';
		set @where_clause = ' WHERE list.IsActive = 1  AND seq.TenantId = '+cast(@tenant_id as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'ListId' or @filter_col = 'SequenceId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH AllIterations AS(SELECT ROW_NUMBER() OVER(ORDER BY iteration.Id DESC) AS RowNumber ,iteration.*,list.Name as ContactListName,seq.Name as SequenceName FROM ContactListSequenceIteration iteration WITH (NOLOCK) inner join ContactListSequence seq WITH (NOLOCK) on seq.Id = iteration.SequenceId inner join Contact_List list WITH (NOLOCK) on iteration.ListId = list.Id ' + @where_clause + ') SELECT *  FROM AllIterations WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
end










GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactListSequenceIterationList_test]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create PROCEDURE [dbo].[SP_GetContactListSequenceIterationList_test] 
    @tenant_id int, 
    @page_no int, 
    @records_per_page int, 
    @filter_col nvarchar(100) = null,
    @filter_by int = null, 
    @total_records int OUTPUT
AS
BEGIN
    IF(dbo.TenantState(@tenant_id) = 1)
    BEGIN
        SET NOCOUNT ON;
       -- SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        DECLARE @count_query nvarchar(max);
        DECLARE @main_query nvarchar(max);
        DECLARE @where_clause nvarchar(max);

        SET @count_query = 'SELECT @total_records = COUNT(*) 
                            FROM ContactListSequenceIteration iteration WITH (NOLOCK)
                            INNER JOIN ContactListSequence seq WITH (NOLOCK) ON seq.Id = iteration.SequenceId
                            INNER JOIN Contact_List list WITH (NOLOCK) ON iteration.ListId = list.Id';
                            
        SET @where_clause = ' WHERE list.IsActive = 1 AND seq.TenantId = ' + CAST(@tenant_id AS varchar);

        IF(@filter_col IS NOT NULL AND @filter_by IS NOT NULL AND (@filter_col = 'ListId' OR @filter_col = 'SequenceId'))
        BEGIN
            SET @where_clause = @where_clause + ' AND ' + @filter_col + ' = ' + CAST(@filter_by AS varchar);
        END
        
        SET @count_query = @count_query + @where_clause;
        EXEC sp_executesql @count_query, N'@total_records int OUTPUT', @total_records OUTPUT;
        
        SET @main_query = 'WITH AllIterations AS (
                            SELECT ROW_NUMBER() OVER (ORDER BY iteration.Id DESC) AS RowNumber, iteration.*, list.Name as ContactListName, seq.Name as SequenceName
                            FROM ContactListSequenceIteration iteration WITH (NOLOCK)
                            INNER JOIN ContactListSequence seq WITH (NOLOCK) ON seq.Id = iteration.SequenceId
                            INNER JOIN Contact_List list WITH (NOLOCK) ON iteration.ListId = list.Id ' + @where_clause + ')
                           SELECT * 
                           FROM AllIterations
                           WHERE RowNumber BETWEEN ((' + CAST(@page_no AS varchar) + '-1) * ' + CAST(@records_per_page AS varchar) + ') + 1
						   AND ' + CAST(@records_per_page AS varchar) + ' * (' + CAST(@page_no AS varchar) + ')';
                           
        EXEC(@main_query);
    END
    ELSE
    BEGIN
        SET @total_records = 0;
    END
END

GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactListSequenceList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetContactListSequenceList] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
	 SET NOCOUNT ON;
      --  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(*) FROM ContactListSequence sequence WITH (NOLOCK) inner join ImportList_Source src WITH (NOLOCK) on src.Id = sequence.SourceId';
		set @where_clause = ' WHERE sequence.IsActive = 1 and src.IsActive = 1 AND sequence.TenantId = '+cast(@tenant_id as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH AllSequences AS(SELECT ROW_NUMBER() OVER(ORDER BY sequence.Id DESC) AS RowNumber ,sequence.*,src.Name as SourceName FROM ContactListSequence sequence WITH (NOLOCK) inner join ImportList_Source src WITH (NOLOCK) on src.Id = sequence.SourceId ' + @where_clause + ') SELECT *  FROM AllSequences WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
END










GO
/****** Object:  StoredProcedure [dbo].[SP_GetContactMapGroupIterationById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_GetContactMapGroupIterationById] @Id int
as begin
select * from ContactMapGroupIteration where Id=@Id
end







GO
/****** Object:  StoredProcedure [dbo].[SP_GetCurrentDayCampaignRealTimeCountDashboard]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetCurrentDayCampaignRealTimeCountDashboard] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql = 'SELECT
                        COUNT(IIF(IL.Status IN(2,7,9,12,14,3,4,6),1,NULL)) as Total,
						ISNULL(SUM(DialAttempts),0) as Dialed,
						--COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Dialed,
						(COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
						--COUNT(IIF(IL.Status IN(2,4,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL)) as Pending,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
						COUNT(IIF(IL.Status IN(6),1,NULL)) as Exclusion,
						COUNT(IIF(IL.Status IN(3),1,NULL)) as Duplicate,
						COUNT(IIF(IL.Status IN(4),1,NULL)) as TotalInvalid
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL  
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1 and cast(IL.CreatedOn as Date) = cast(getutcdate() as Date)';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END


GO
/****** Object:  StoredProcedure [dbo].[SP_GetCurrentDayCampaignRealTimeCountDashboard_Latest]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_GetCurrentDayCampaignRealTimeCountDashboard_Latest]   --6736    
 @campaign_id int          
 AS BEGIN          
      
create table #temp1( CallingList nvarchar(max), TotalPending int);    
    
create table #temp2(CallingList nvarchar(max), Total int, Dialed int, Pending int, TotalConnect int,    
     TotalAbandoned int, Exclusion int, Duplicate int, TotalInvalid int, Rechurn int);    
    
    
 Declare @totalPending nvarchar(max);        
 set @totalPending = 'insert into #temp1(CallingList,TotalPending)  SELECT             
                      CL.Name as CallingList, (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9)      
   AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) TotalPending        
   FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL           
      INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId          
      INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId          
      INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1                
      GROUP BY CL.Name'        
        
 execute sp_executesql @totalPending, N'@campaign_id int', @campaign_id ;          
        
 DECLARE @sql nvarchar(MAX);          
 SET @sql = ' insert into #temp2(CallingList, Total, Dialed, Pending, TotalConnect,TotalAbandoned,    
         Exclusion, Duplicate, TotalInvalid, Rechurn)     
 SELECT             
      CL.Name as CallingList,          
      COUNT(IIF(IL.Status IN(2,7,9,12,14,3,4,6),1,NULL)) as Total,          
      ISNULL(SUM(DialAttempts),0) as Dialed,          
      (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,          
      COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,          
      COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,          
      COUNT(IIF(IL.Status IN(6),1,NULL)) as Exclusion,          
      COUNT(IIF(IL.Status IN(3),1,NULL)) as Duplicate,          
      COUNT(IIF(IL.Status IN(4),1,NULL)) as TotalInvalid,  
   case when isnull(sum(IL.ImportAttempts),0) > 0 then isnull(sum(IL.ImportAttempts),0) -1 else isnull(sum(IL.ImportAttempts),0) end as ReChurnAttempts            
      FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL           
      INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId          
      INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId          
      INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1          
      and cast(IL.CreatedOn as Date) = cast(getutcdate() as Date)          
      GROUP BY CL.Name'       
       
   execute sp_executesql @sql, N'@campaign_id int', @campaign_id;          
      
  --select * from #temp1;    
  --select * from #temp2;    
      
  --7.9, 14    
    
  select case when SUM (isnull(t2.Total,0))< SUM(isnull(t1.TotalPending,0)) then SUM(isnull(t1.TotalPending,0)) + SUM(isnull(t2.Dialed,0)) +    
  SUM(isnull(TotalConnect,0))+ SUM(isnull(TotalAbandoned,0)) +  SUM(isnull(Exclusion,0)) +SUM(isnull(Duplicate,0)) +  SUM(isnull(TotalInvalid,0))  
  else SUM (isnull(t2.Total,0)) end Total ,  
   SUM(isnull(t2.Dialed,0)) Dialed, SUM(isnull(t1.TotalPending,0)) as Pending,    
                      SUM(isnull(TotalConnect,0)) TotalConnect, SUM(isnull(TotalAbandoned,0))TotalAbandoned ,    
       SUM(isnull(Exclusion,0)) Exclusion, SUM(isnull(Duplicate,0)) Duplicate, SUM(isnull(TotalInvalid,0)) TotalInvalid    
  from #temp1 t1 left join #temp2 t2    
  on t1.CallingList = t2.CallingList;    
    
  drop table #temp1;    
  drop table #temp2;    
      
     
  END


GO
/****** Object:  StoredProcedure [dbo].[SP_GetCurrentDayCampaignRealTimeStatus_ListWiseCountDashboard]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_GetCurrentDayCampaignRealTimeStatus_ListWiseCountDashboard]
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	SET @sql = 'SELECT   
						CL.Name as CallingList,
						COUNT(IIF(IL.Status IN(2,7,9,12,14,3,4,6),1,NULL)) as Total,
						ISNULL(SUM(DialAttempts),0) as Dialed,
						(COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,
						COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,
						COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,
						COUNT(IIF(IL.Status IN(6),1,NULL)) as Exclusion,
						COUNT(IIF(IL.Status IN(3),1,NULL)) as Duplicate,
						COUNT(IIF(IL.Status IN(4),1,NULL)) as TotalInvalid
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL 
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1
						and cast(IL.CreatedOn as Date) = cast(getutcdate() as Date)
						GROUP BY CL.Name'
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END


GO
/****** Object:  StoredProcedure [dbo].[SP_GetCurrentDayCampaignRealTimeStatus_ListWiseCountDashboard_Latest]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[SP_GetCurrentDayCampaignRealTimeStatus_ListWiseCountDashboard_Latest] --6736       
 @campaign_id int            
 AS BEGIN            
        
create table #temp1( CallingList nvarchar(max), TotalPending int);      
      
create table #temp2(CallingList nvarchar(max), Total int, Dialed int, Pending int, TotalConnect int,      
     TotalAbandoned int, Exclusion int, Duplicate int, TotalInvalid int, Rechurn int);      
      
      
 Declare @totalPending nvarchar(max);          
 set @totalPending = 'insert into #temp1(CallingList,TotalPending)  SELECT               
                      CL.Name as CallingList, (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9)        
   AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9) AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) TotalPending          
   FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL             
      INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId            
      INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId            
      INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1                  
      GROUP BY CL.Name'          
          
 execute sp_executesql @totalPending, N'@campaign_id int', @campaign_id ;            
          
 DECLARE @sql nvarchar(MAX);            
 SET @sql = ' insert into #temp2(CallingList, Total, Dialed, Pending, TotalConnect,TotalAbandoned,      
         Exclusion, Duplicate, TotalInvalid, Rechurn)       
 SELECT               
      CL.Name as CallingList,            
      COUNT(IIF(IL.Status IN(2,7,9,12,14,3,4,6),1,NULL)) as Total,            
      ISNULL(SUM(DialAttempts),0) as Dialed,            
      (COUNT(IIF(IL.Status IN(2,7,9,12,14),1,NULL))-COUNT(IIF(IL.Status IN(12,9) AND DialAttempts>0,1,NULL))+COUNT(IIF(IL.Status IN(12,9)     
   AND (ImportAttempts>DialAttempts AND CallResult !=0),1,NULL))) Pending,            
      COUNT(IIF(IL.Status = 12 OR (CallResult = 10 and IL.Status = 9),1,NULL)) as TotalConnect,            
      COUNT(IIF(IL.Status IN(9,12) AND (CallResult IN(16,20,21)),1,NULL)) as TotalAbandoned,            
      COUNT(IIF(IL.Status IN(6),1,NULL)) as Exclusion,            
      COUNT(IIF(IL.Status IN(3),1,NULL)) as Duplicate,            
      COUNT(IIF(IL.Status IN(4),1,NULL)) as TotalInvalid,    
   case when isnull(sum(IL.ImportAttempts),0) > 0 then isnull(sum(IL.ImportAttempts),0) -1 else isnull(sum(IL.ImportAttempts),0) end as ReChurnAttempts            
      FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL     
  -- from Import_List_Table_6739 IL    
               
      INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId            
      INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId            
      INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1            
      and cast(IL.CreatedOn as Date) = cast(getutcdate() as Date)            
      GROUP BY CL.Name'         
         
   execute sp_executesql @sql, N'@campaign_id int', @campaign_id;            
        
  --select * from #temp1;      
  --select * from #temp2;      
        
  --7.9, 14      
      
     select t1.CallingList, case when isnull(t1.TotalPending,0)> isnull(t2.Total,0) then (isnull(t1.TotalPending,0)  +  isnull(t2.Rechurn ,0))else (isnull(t2.Total,0))  end Total, isnull(t2.Dialed,0) Dialed, isnull(t1.TotalPending
,0) as Pending,    
                      isnull(TotalConnect,0) TotalConnect, isnull(TotalAbandoned,0)TotalAbandoned ,    
       isnull(Exclusion,0) Exclusion, isnull(Duplicate,0) Duplicate, isnull(TotalInvalid,0) TotalInvalid 
  from #temp1 t1 left join #temp2 t2    
  on t1.CallingList = t2.CallingList;    
        
      
  drop table #temp1;      
  drop table #temp2;      
        
       
  END 


GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDealer] as begin
select * from Dealer where IsActive=1
END









GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerAgentMapList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDealerAgentMapList] @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output as 
begin
	
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM DealerExtraDetails DED inner join UCCEAgent agent on DED.AgentId = agent.PeripheralNumber ';
		set @where_clause = ' WHERE  DED.IsActive=1';
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'DealerId' or @filter_col = 'AgentId' or @filter_col = 'IsActive'))  
		begin
			set @where_clause = @where_clause +' AND DED.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Maps AS(SELECT ROW_NUMBER() OVER(ORDER BY MapId DESC) AS RowNumber ,DED.*,agent.LoginName,agent.PeripheralNumber  FROM DealerExtraDetails DED inner join UCCEAgent agent on DED.AgentId = agent.PeripheralNumber ' + @where_clause + ') SELECT *  FROM All_Maps WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ';
		exec(@main_query);
	end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerAgentsList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDealerAgentsList] @tenant_id int,@dealerId int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output as 
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM UCCEAgent ua inner join DealerExtraDetails ded on ded.AgentId=ua.PeripheralNumber';
		set @where_clause = ' WHERE ded.IsActive = 1 and ded.TenantId = '+cast(@tenant_id as varchar)+'and DealerId='+cast(@dealerId as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'AgentId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Agents AS(SELECT ROW_NUMBER() OVER(ORDER BY ded.MapId DESC) AS RowNumber ,ua.*,ded.MapId FROM UCCEAgent ua inner join DealerExtraDetails ded on ded.AgentId=ua.PeripheralNumber  ' + @where_clause + ') SELECT *  FROM All_Agents WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerApiSource]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDealerApiSource] @dealerId int , @dealerName varchar(max)
  as begin 
    SELECT * FROM ImportList_Source ils
	inner join Dealer d on ils.DealerId=d.DealerId
	where Name=@dealerName   and ils.DealerId=@dealerId and ils.IsActive=1 and d.IsActive=1
  end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDealerById] @Id int as begin
select * from Dealer where DealerId=@Id and IsActive=1 
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerBySkill]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE Procedure [dbo].[SP_GetDealerBySkill] @skilltargetid int as
  begin

  Select d.*,ded.SkillTargetID from [dbo].[DealerExtraDetails] ded inner join [dbo].[Dealer] d on d.DealerId=ded.DealerId and ded.IsActive=1 and d.IsActive=1 and ded.SkillTargetID=@skilltargetid

  end







GO
/****** Object:  StoredProcedure [dbo].[sp_getDealerCampaignDetails]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE proc [dbo].[sp_getDealerCampaignDetails]
as
begin
-- Function    : sp_getDealerCampaignDetails
--
-- Description : Procedure to get Campaign and Dealers Details.
--
-- Version     : 1.0.0
--
-- Author      : consilium software inc.
--
--
-- Change Information.
-- -------------------------------
-- 
-- Who                    Date              Reason.
-- -----------------------------------------------------------------------------------------------------------------
-- Shubham Singh          22-july-2019       Created. 
--
-------------------------------------------------------------------------------------------------------------------- 
	select distinct ils.DealerId as SourceDealerID , ccl.CampaignId as CampaignIDs, 
	 	    isnull(clis.TotalRecordImported,0) as TotalSalesBooked, 
	 		isnull([dbo].[getThreshold](ccl.ExtraDetails),0) as Threshold
	 		-- isnull(ccl.ExtraDetails,'') as ExtraDetails 
	 		, isnull(cr.WrapupData,0)WrapupData  into #temp
	 		from 
	 CampaignContact_List ccl inner join Contact_List cl 
	 on ccl.ListId= cl.Id
	 inner join ImportList_Source ils on cl.SourceId = ils.Id
	 Left join [dbo].[ContactList_ImportStatus] clis on clis.CampaignList_Id = ccl.CampaignList_Id
	 Left join Import_List_Table_6066 il on il.MapId = ccl.CampaignList_Id and il.AttemptId = clis.CampaignList_Id
	 left join Call_Result_Table_6066 cr on cr.ImportList_Id = il.ImportList_Id
	 where cl.isActive= 1 and ils.isActive = 1
	 and ccl.isActive = 1
	 

	 select SourceDealerID, count(WrapupData) totalCompletedCalls
	 from #temp
	-- where WrapupData <> 0
	 group by SourceDealerID;

	 select * from #temp;

	 drop table #temp;

end





GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerExtraDetailsByMApId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_GetDealerExtraDetailsByMApId] @itemId int  as
	begin

	Select * from DealerExtraDetails de
	inner join Dealer d on de.DealerId=d.DealerId
	 where MapId=@itemId  and d.IsActive=1;
	end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDealerList] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM Dealer dl';
		set @where_clause = ' WHERE dl.IsActive = 1';
		if(@filter_col is not null and @filter_by is not null)  
		begin
			if(@filter_col = 'CreatedOn')
			begin
				set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			end
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND dl.DealerName like ''%'+@search_term+'%''';
		end
		set @where_clause = @where_clause ;
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_DealerList AS (SELECT ROW_NUMBER() OVER(ORDER BY dl.DealerId DESC) AS RowNumber ,dl.* FROM Dealer dl ' + @where_clause + ') SELECT * FROM All_DealerList WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		end
	else
		set @total_records = 0;
END









GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerskillMapList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDealerskillMapList] @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output as 
begin
	
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM DealerExtraDetails  ';
		set @where_clause = ' WHERE IsActive=1';
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'DealerId' or @filter_col = 'SkillTargetID' or @filter_col = 'IsActive'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Maps AS(SELECT ROW_NUMBER() OVER(ORDER BY MapId DESC) AS RowNumber ,* FROM DealerExtraDetails  ' + @where_clause + ') SELECT *  FROM All_Maps WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ';
		exec(@main_query);
	end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerskillMapList_new]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetDealerskillMapList_new] @searchTerm nvarchar(255)=null,@page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output as 
begin
	
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM DealerExtraDetails  ';
		set @where_clause = ' WHERE IsActive=1';
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'DealerId' or @filter_col = 'SkillTargetID' or @filter_col = 'IsActive'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@searchTerm is not null)
		begin
		set @where_clause = @where_clause +' AND EnterpriseName like ''%'+@searchTerm +'%''';
		end
		set @count_query = @count_query + @where_clause;
		
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Maps AS(SELECT ROW_NUMBER() OVER(ORDER BY MapId DESC) AS RowNumber ,* FROM DealerExtraDetails  ' + @where_clause + ') SELECT *  FROM All_Maps WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ';
		exec(@main_query);
	end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerSkillsList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDealerSkillsList] @tenant_id int,@dealerId int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output as 
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM UCCE_Skill_Group ua inner join DealerExtraDetails ded on ded.SkillTargetID=ua.SkillTargetID';
		set @where_clause = ' WHERE ded.IsActive = 1 and ded.TenantId = '+cast(@tenant_id as varchar)+'and DealerId='+cast(@dealerId as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'ua.SkillTargetID'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND ua.EnterpriseName like ''%'+@search_term+'%''';
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Agents AS(SELECT ROW_NUMBER() OVER(ORDER BY ded.MapId DESC) AS RowNumber ,ua.*,ded.MapId FROM UCCE_Skill_Group ua inner join DealerExtraDetails ded on ded.SkillTargetID=ua.SkillTargetID  ' + @where_clause + ') SELECT *  FROM All_Agents WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
end







GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerSpecificAgentWrapUpCode]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_GetDealerSpecificAgentWrapUpCode] @agent_id int 
as
begin
if(dbo.TenantState(1000)=1)
begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select DealerId FROM DealerExtraDetails DED';
		set @where_clause = ' WHERE DED.IsActive = 1 AND AgentId ='''+ @agent_id +';'
		set @main_query=@count_query+ @where_clause;
		Select @main_query;
end
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetDealerWrapUpCode]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_GetDealerWrapUpCode]
@agent_LoginId nvarchar(255)=null,
@agent_LoginName nvarchar(255)=null,
@dealer_Id int output
as 
begin
if(dbo.TenantState(1000)=1)
begin
declare @query_clause nvarchar(max);
declare @select_wrapUpCode nvarchar(max);
if(@agent_LoginId is not null)
begin 
set @query_clause='Select @dealer_Id= DealerId from DealerExtraDetails where IsActive=1 and AgentId ='''+ @agent_LoginId+''';'
execute sp_executesql @query_clause, N'@dealer_Id int output',@dealer_Id output;
end
else
begin
set @query_clause='Select @dealer_Id= DealerId from DealerExtraDetails where IsActive=1 and AgentLoginName ='''+ @agent_LoginName+''';'
execute sp_executesql @query_clause, N'@dealer_Id int output',@dealer_Id output; 
end 
if(@dealer_Id > 0)
begin
 set @select_wrapUpCode='Select WrapUpCodeName from PreviewWarpReasonCode where IsActive=1 and DealerId='+ CAST(@dealer_Id as varchar(100)) ;
exec(@select_wrapUpCode);
end
end
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetDialerDataByDay]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetDialerDataByDay] @tenant_id int, @status int , @number_of_records int = 100 as 
begin
	declare @sql nvarchar(max), @table_name nvarchar(100), @tenant_id_str nvarchar(20), @status_str nvarchar(4), @records_to_fetch_str nvarchar(20);
	set @tenant_id_str = cast(@tenant_id as nvarchar(20));
	set @records_to_fetch_str = cast(@number_of_records as nvarchar(20));
	set @table_name = 'Outbound_Call_Detail_'+@tenant_id_str;
	set @status_str = cast(@status as nvarchar(4));
	set @sql = '
				select top '+@records_to_fetch_str+'  ocd.*
				from '+@table_name+' ocd 
				where ocd.CampaignID in (select CampaignId from CBMConfig where TenantId = '+@tenant_id_str+' and Level > 0)
				and Convert(date,ocd.DateTimeUtc) = convert(date,getutcdate()) 
				and ocd.Status = '+@status_str+' order by ocd.RecoveryKey asc, CampaignID asc
	';
	execute sp_executesql @sql;
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetDialingList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDialingList] @tenant_id int, @status int, @batch_size int as begin
	if(dbo.TenantState(@tenant_id)=1)
	begin
	declare @table_name nvarchar(100);
	set @table_name = 'Import_List_'+cast(@tenant_id as nvarchar);
	declare @sql nvarchar(max);
	set @sql = '
		select	top '+CAST(@batch_size as nvarchar)+
			' ImportList_Id,AttemptId,MapId,CampaignId,Phone01,AccountNumber,FirstName,LastName,Phone02,
			Phone03,Phone04,Phone05,Phone05,Phone06,Phone07,Phone08,Phone09,Phone10,TimeZoneBias,DstObserved,
			PhoneToCallNext,DateTime,ScheduledDateTime
		from '+@table_name+' where Status = '+CAST(@status as nvarchar)+
		'
			order by ScheduledDateTime asc
		';
	execute sp_executesql @sql;
	end
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetDialingListAPI]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetDialingListAPI] @campaign_id int, @list_id int , @tenant_id int, @status int, @batch_size int as begin
	if(dbo.TenantState(@tenant_id)=1)
	begin
	declare @table_name nvarchar(100);
	set @table_name = 'API_Import_List_Table_'+cast(@campaign_id as nvarchar);
	declare @sql nvarchar(max);
	set @sql = '
		select	top '+CAST(@batch_size as nvarchar)+
			' ImportList_Id,AttemptId,MapId,CampaignId,Phone01,AccountNumber,FirstName,LastName,Phone02,
			Phone03,Phone04,Phone05,Phone05,Phone06,Phone07,Phone08,Phone09,Phone10,TimeZoneBias,DstObserved,
			PhoneToCallNext,DateTime,ScheduledDateTime
		from '+@table_name+' where MapId = ' +cast(@list_id as nvarchar) +' and Status = '+CAST(@status as nvarchar)+ 
		'
			order by ScheduledDateTime asc
		';
	execute sp_executesql @sql;
	end
end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetDialingListCampaignBased]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetDialingListCampaignBased] @campaign_id int, @list_id int , @tenant_id int, @status int, @batch_size int as begin
	if(dbo.TenantState(@tenant_id)=1)
	begin
	declare @table_name nvarchar(100);
	set @table_name = 'Import_List_Table_'+cast(@campaign_id as nvarchar);
	declare @sql nvarchar(max);
	set @sql = '
		select	top '+CAST(@batch_size as nvarchar)+
			' ImportList_Id,AttemptId,MapId,CampaignId,Phone01,AccountNumber,FirstName,LastName,Phone02,
			Phone03,Phone04,Phone05,Phone05,Phone06,Phone07,Phone08,Phone09,Phone10,TimeZoneBias,DstObserved,
			PhoneToCallNext,DateTime,ScheduledDateTime
		from '+@table_name+' where MapId = ' +cast(@list_id as nvarchar) +' and Status = '+CAST(@status as nvarchar)+ 
		'
			order by ScheduledDateTime asc
		';
	execute sp_executesql @sql;
	end
end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetDialingMultiList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetDialingMultiList] @tenant_id int, @status int, @batch_size int as begin
	if(dbo.TenantState(@tenant_id)=1)
	begin
	declare @table_name nvarchar(100);
	set @table_name = 'Import_MultiList_'+cast(@tenant_id as nvarchar);
	declare @sql nvarchar(max);
	set @sql = '
		select	top '+CAST(@batch_size as nvarchar)+
			' ImportList_Id,AttemptId,MapId,CampaignId,Phone01,AccountNumber,FirstName,LastName,Phone02,
			Phone03,Phone04,Phone05,Phone05,Phone06,Phone07,Phone08,Phone09,Phone10,TimeZoneBias,DstObserved,
			PhoneToCallNext,DateTime,ScheduledDateTime
		from '+@table_name+' where Status = '+CAST(@status as nvarchar)+
		'
			order by ScheduledDateTime asc
		';
	execute sp_executesql @sql;
	end
end













GO
/****** Object:  StoredProcedure [dbo].[SP_GetDNCRulebyId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetDNCRulebyId] @Id int as begin
select * from DNCRule where DNCId=@Id
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetEligibleScedule]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetEligibleScedule]  @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin

		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM RecurrenceSchedule';
		set @where_clause = '  where  ( Status=1 or Status=17) ';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'ScheduleType'))  
		begin
			set @where_clause = 'and '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'NextIterationDate'))  
		begin
			set @where_clause = @filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND Name like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_RecurrenceSchedules AS(SELECT ROW_NUMBER() OVER(ORDER BY Id DESC) AS RowNumber ,Id,Name,Description ,ScheduleType,Frequency,RecurrenceInterval,RecurrenceUnit,StartDateTime,EndDateTime,Status,CreatedOn,LastUpdatedOn,NextIterationDate FROM RecurrenceSchedule ' + @where_clause + ') SELECT Id,Name,Description ,ScheduleType,Frequency,RecurrenceInterval,RecurrenceUnit,StartDateTime,EndDateTime,Status,CreatedOn,LastUpdatedOn,NextIterationDate FROM All_RecurrenceSchedules WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end





GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetEmailCampaign] @email_campaign_id int as
begin

Select camp.*,conf.Name as EmailConfigName from EmailCampaign camp inner join EmailConfiguration conf on camp.EmailConfigId=conf.EmailConfigID where camp.EmailCampaignId=@email_campaign_id and camp.IsActive=1 and conf.IsActive=1
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailCampaignList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetEmailCampaignList]
@tenant_id int,
@dealer_id int,
@page_no int,
@records_per_page int,
@filter_col nvarchar(100)=null,
@filter_by int=null,
@total_records int output
as begin
if(dbo.TenantState(@tenant_id)=1)
begin
declare @count_query nvarchar(max);
declare @main_query nvarchar(max);
declare @where_clause nvarchar(max);
set @count_query='select @total_records =COUNT(*) FROM EmailCampaign camp';
set @where_clause= ' inner join EmailConfiguration conf on camp.EmailConfigId=conf.EmailConfigID WHERE camp.IsActive = 1 and conf.IsActive = 1 AND camp.TenantId = '+cast(@tenant_id as varchar) +'AND camp.DealerId = '+cast(@dealer_id as varchar); 
if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Name' or @filter_col = 'EmailConfigId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH AllEmailCampaigns AS(SELECT ROW_NUMBER() OVER(ORDER BY EmailCampaignId DESC) AS RowNumber ,camp.*, conf.Name as EmailConfigName from EmailCampaign camp ' + @where_clause + ') SELECT *  FROM AllEmailCampaigns WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailContactMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetEmailContactMap]
	@tenant_id int, 
	@map_id int
as begin
	select map.*,list.Name as ContactList, camp.Name as Campaign from EmailCampaign_ContactList map 
	inner join Contact_List list on map.ContactListId = list.Id
	inner join EmailCampaign camp on camp.EmailCampaignId = map.CampaignId
	where map.TenantId = @tenant_id and map.Id = @map_id and list.IsActive = 1 and camp.IsActive = 1 
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailContactMapList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetEmailContactMapList] 
	@tenant_id int, 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@total_records int output 
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM EmailCampaign_ContactList map ';
		set @where_clause = 'inner join Contact_List list on map.ContactListId = list.Id inner join EmailCampaign camp on camp.EmailCampaignId = map.CampaignId ' ;
		set @where_clause = @where_clause+'WHERE map.TenantId = '+cast(@tenant_id as varchar);
		
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'ContactListId' or @filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND map.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Maps AS(SELECT ROW_NUMBER() OVER(ORDER BY map.Id DESC) AS RowNumber ,map.*,list.Name as ContactList, camp.Name as Campaign from EmailCampaign_ContactList map ' + @where_clause + ') SELECT *  FROM All_Maps WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailImportList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[SP_GetEmailImportList] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id int = null,@attempt_id int = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		set @table_name='Email_List_'+cast(@tenant_id as varchar);
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name;
		set @where_clause = ' Where CampaignId = '+cast(@campaign_id as varchar);
		if(@map_id is not null)
		begin
			set @where_clause += 'AND MapId = '+cast(@map_id as varchar);
		end
		if(@attempt_id is not null)
		begin
			set @where_clause += 'AND AttemptId = '+cast(@attempt_id as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status' or @filter_col='EmailResult'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'With ImportList as (
							SELECT ROW_NUMBER() OVER(ORDER BY CreatedOn DESC) AS RowNumber, * from '+ @table_name  
							+ @where_clause + ') SELECT Id,EmailAddress,Status,EmailResult,CreatedOn,ProcessedOn from ImportList WHERE RowNumber BETWEEN 
							(('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
		return;
	end
		set @total_records = 0;
END








GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetEmailList] @tenant_id int, @status int, @batch_size int as begin
	if(dbo.TenantState(@tenant_id)=1)
	begin
	declare @table_name nvarchar(100);
	set @table_name = 'Email_List_'+cast(@tenant_id as nvarchar);
	declare  @current_time time; 
	declare @current_date date;
	set @current_time = convert(time,getdate());
	set @current_date = convert(date,getdate());
	declare @sql nvarchar(max);
	set @sql = '
		select	top '+CAST(@batch_size as nvarchar)+
			' * from '+@table_name+' where Status = '+CAST(@status as nvarchar)+
		'	and CampaignId in (SELECT EmailCampaignId from EmailCampaign where IsActive = 1 and State = 1 )
			order by Id asc
		';
	execute sp_executesql @sql;
	end
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetEmailStatus] 
	@tenant_id int,
	@status_id int
as begin
	select st.* from EmailContactList_Status st 
			where st.Id = @status_id and st.TenantId = @tenant_id
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetEmailStatusList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetEmailStatusList] 
	@tenant_id int, 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@sort_col nvarchar(100) = null, 
	@sort_direction nvarchar(10) = 'desc', 
	@total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM EmailContactList_Status ';
		set @where_clause = 'WHERE TenantId =' +CAST(@tenant_id as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'MapId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH AllStatus AS (SELECT ROW_NUMBER() OVER(ORDER BY Id DESC) AS RowNumber ,* from EmailContactList_Status ' + @where_clause + ') SELECT * FROM AllStatus WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';	
		if(@sort_col is not null and @sort_col = 'LastAttemptedOn')
		begin
			set @main_query = @main_query + ' ORDER BY '+@sort_col + ' '+@sort_direction;
		end
		exec(@main_query)
	end
	else
		set @total_records = 0;
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetGlobalDNCMapByID]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetGlobalDNCMapByID] 
@DNC_Id INT 
AS
BEGIN
		SELECT * FROM GlobalDNCMap gdm
		WHERE DNCMapId =@DNC_Id
END




GO
/****** Object:  StoredProcedure [dbo].[SP_GetGroupById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetGroupById] @Id int as
begin
	select h.* from GroupMaster h 
    left Join Dealer d on h.DepartmentId= d.DealerId
	where Id = @Id and h.IsActive = 1 and (d.IsActive=1 or h.DepartmentId=-1)
end


GO
/****** Object:  StoredProcedure [dbo].[SP_GetGroupIdByCampaignId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetGroupIdByCampaignId] @CampaignId int as
begin
	select h.GroupId from CampaignGroupMaster h 
    
	where CampaignId = @CampaignId and h.IsActive = 1 
end


GO
/****** Object:  StoredProcedure [dbo].[SP_GetGroupList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetGroupList] @tenant_id int,@DealerId int=null, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output as 
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM GroupMaster h';
		set @where_clause = ' WHERE h.IsActive = 1 and h.TenantId = '+cast(@tenant_id as varchar)+' ';
		set @where_clause = @where_clause;
		if(@DealerId != 0)  
		begin
			set @where_clause = @where_clause +'and (h.DepartmentId = '+cast(@DealerId as varchar)+' or h.DepartmentId=-1)';
		end
		
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end

		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND h.Name like ''%'+@search_term+'%''';
		end

		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Holidays AS(SELECT ROW_NUMBER() OVER(ORDER BY h.Id DESC) AS RowNumber ,h.* FROM GroupMaster h  ' + @where_clause + ') SELECT *  FROM All_Holidays WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
		--select(@main_query);
		--print(@main_query);
	end
	else
		set @total_records = 0;
end


GO
/****** Object:  StoredProcedure [dbo].[SP_GetHolidayById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetHolidayById] @holiday_id int as
begin
	select h.* from Holiday h 
    left Join Dealer d on h.DealerId= d.DealerId
	where HolidayId = @holiday_id and h.IsActive = 1 and (d.IsActive=1 or h.DealerId=-1)
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetHolidayCampaignMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetHolidayCampaignMap] @map_id int as begin
	select map.*,holiday.Name as HolidayName from CampaignHoliday map inner join Holiday holiday on holiday.HolidayId = map.HolidayId where map.Id = @map_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetHolidayCampaignMapList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetHolidayCampaignMapList] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output as 
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM CampaignHoliday map inner join Holiday holiday on holiday.HolidayId = map.HolidayId ';
		set @where_clause = ' WHERE map.TenantId = '+cast(@tenant_id as varchar);
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'Status' or @filter_col = 'HolidayId'))  
		begin
			set @where_clause = @where_clause +' AND map.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Maps AS(SELECT ROW_NUMBER() OVER(ORDER BY Id DESC) AS RowNumber ,map.*,holiday.Name as HolidayName FROM CampaignHoliday map inner join Holiday holiday on holiday.HolidayId = map.HolidayId ' + @where_clause + ') SELECT *  FROM All_Maps WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') order by DateTime asc';
		exec(@main_query);
	end
	else
		set @total_records = 0;
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetHolidayList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetHolidayList] @tenant_id int,@DealerId int=null, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output as 
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM Holiday h';
		set @where_clause = ' WHERE h.IsActive = 1 and h.TenantId = '+cast(@tenant_id as varchar)+' ';
		set @where_clause = @where_clause;
		if(@DealerId != 0)  
		begin
			set @where_clause = @where_clause +'and (h.DealerId = '+cast(@DealerId as varchar)+' or h.DealerId=-1)';
		end
		
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end

		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND h.Name like ''%'+@search_term+'%''';
		end

		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Holidays AS(SELECT ROW_NUMBER() OVER(ORDER BY h.HolidayId DESC) AS RowNumber ,h.* FROM Holiday h  ' + @where_clause + ') SELECT *  FROM All_Holidays WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
		--select(@main_query);
		--print(@main_query);
	end
	else
		set @total_records = 0;
end




GO
/****** Object:  StoredProcedure [dbo].[SP_GetHolidayList1]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetHolidayList1] @tenant_id int,@DealerId int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @total_records int output as 
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM Holiday h';
		set @where_clause = ' WHERE h.IsActive = 1 and h.TenantId = '+cast(@tenant_id as varchar)+' and (h.DealerId = '+cast(@DealerId as varchar)+' or h.DealerId=-1)';
		set @where_clause = @where_clause;
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Holidays AS(SELECT ROW_NUMBER() OVER(ORDER BY h.HolidayId DESC) AS RowNumber ,h.* FROM Holiday h  ' + @where_clause + ') SELECT *  FROM All_Holidays WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
		--select(@main_query);
		--print(@main_query);
	end
	else
		set @total_records = 0;
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportAttemportByCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetImportAttemportByCampaign] 
	@campaign_id int
AS BEGIN
	DECLARE @sql nvarchar(MAX);
	           SET @sql ='SELECT                  
                        Distinct ImportAttempts
						FROM Import_List_Table_'+CAST(@campaign_id AS nvarchar)+'  IL    
						INNER JOIN CampaignContact_List IT ON IT.CampaignList_Id = IL.MapId
						INNER JOIN ContactList_ImportStatus ST ON ST.CampaignList_Id = IL.AttemptId
						INNER Join Contact_List CL on IT.ListId=CL.Id where CL.IsActive=1';
	execute sp_executesql @sql, N'@campaign_id int', @campaign_id;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[SP_GetImportList] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id int = null,@attempt_id int = null,@wrapupData nvarchar(40) = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		declare @sub_where_clasue nvarchar(max);
		declare @sub_count_query nvarchar(max);
		set @table_name='Import_List_Table_'+cast(@campaign_id as varchar);
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name;
		set @where_clause = ' 1=1  ';
		set @sub_where_clasue= ' ';
		if(@map_id is not null)
		begin
			set @where_clause = @where_clause +' AND MapId = '+cast(@map_id as varchar);
		end
		if(@attempt_id is not null)
		begin
			
			set @where_clause += ' AND AttemptId = '+cast(@attempt_id as varchar);
		end

		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status') or (@filter_col = 'CallResult') or (@filter_col = 'AgentId'))  
		begin					
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@wrapupData is not null or @wrapupData != '' or @wrapupData != 'null')
		begin
		set @sub_count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+' IL inner join ' + 'Call_Result_Table_'+cast(@campaign_id as varchar)+ ' CR on IL.ImportList_Id=CR.ImportList_Id ';
		set @sub_where_clasue += ' CR.WrapupData = '''+@wrapupData+''' AND '  
		end		
		begin
			set @where_clause = ' WHERE ' + @where_clause;
		end
		if(@wrapupData is null or @wrapupData = '' or @wrapupData = 'null')
		begin
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
        set @main_query = 'With ImportList as (
							SELECT ROW_NUMBER() OVER(ORDER BY CreatedOn DESC) AS RowNumber, * from '+ @table_name  
							+ @where_clause + ') SELECT Import.ImportList_Id as Id,Import.Phone01 as Phone01,Import.AccountNumber as AccountNumber,Import.FirstName as FirstName,Import.LastName as LastName,Import.Phone02 as Phone02,Import.Phone03 as Phone03,Import.Phone04 as Phone04,Import.Phone05 as Phone05,Import.Phone06 as Phone06,Import.Phone07 as Phone07,Import.Phone08 as Phone08,Import.Phone09 as Phone09,Import.Phone10 as Phone10,Import.Status as Status,Import.CallResult as CallResult,Import.AgentName as AgentName,Import.CreatedOn as CreatedOn,Import.ImportDateTime as ImportDateTime ,Import.AttemptsMade as DialAttempts ,CR.WrapupData as WrapupData ,CR.CallDateTime as CallDateTime ,Import.ImportAttempts as ReChurnAttempts from ImportList Import left join (
                             SELECT ImportList_Id,Max(CallDateTime) As CallDateTime,CASE WHEN MAX(CASE WHEN WrapupData IS NULL THEN 1 ELSE 0 END) = 0 THEN MAX(WrapupData) END As WrapupData FROM Call_Result_Table_'+cast(@campaign_id as varchar)+' GROUP BY ImportList_Id )     CR on Import.ImportList_Id=CR.ImportList_Id WHERE RowNumber BETWEEN 
							(('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		end		
		else
		begin
		set @sub_count_query = @sub_count_query + @where_clause ;
		set @sub_count_query += 'AND  CR.WrapupData = '''+@wrapupData+''' '
		execute sp_executesql @sub_count_query, N'@total_records int output',@total_records output;
		set @main_query = 'With ImportList as (
							SELECT ROW_NUMBER() OVER(ORDER BY CreatedOn DESC) AS RowNumber, * from '+ @table_name  
							+ @where_clause + ') SELECT Import.ImportList_Id as Id,Import.Phone01 as Phone01,Import.AccountNumber as AccountNumber,Import.FirstName as FirstName,Import.LastName as LastName,Import.Phone02 as Phone02,Import.Phone03 as Phone03,Import.Phone04 as Phone04,Import.Phone05 as Phone05,Import.Phone06 as Phone06,Import.Phone07 as Phone07,Import.Phone08 as Phone08,Import.Phone09 as Phone09,Import.Phone10 as Phone10,Import.Status as Status,Import.CallResult as CallResult,Import.AgentName as AgentName,Import.CreatedOn as CreatedOn,Import.ImportDateTime as ImportDateTime ,Import.AttemptsMade as DialAttempts ,CR.WrapupData as WrapupData,CR.CallDateTime as CallDateTime , Import.ImportAttempts as ReChurnAttempts from ImportList Import inner join (
                            SELECT ImportList_Id,Max(CallDateTime) As CallDateTime,CASE WHEN MAX(CASE WHEN WrapupData IS NULL THEN 1 ELSE 0 END) = 0 THEN MAX(WrapupData) END As WrapupData FROM Call_Result_Table_'+cast(@campaign_id as varchar)+' GROUP BY ImportList_Id )   CR on Import.ImportList_Id=CR.ImportList_Id   WHERE ' + @sub_where_clasue + ' RowNumber BETWEEN 
							(('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+ 1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'; 
		end
		exec(@main_query);		
	end
END










GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportListNew]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetImportListNew] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id nvarchar(max) = null,@attempt_id int = null,@wrapupData nvarchar(40) = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
set nocount on;
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		declare @sub_where_clasue nvarchar(max);
		declare @sub_count_query nvarchar(max);
		set @table_name='Import_List_Table_'+cast(@campaign_id as varchar);
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+ ' ilt (nolock)';
		set @where_clause = ' 1=1  ';
		set @sub_where_clasue= ' ';
		if(@map_id is not null)
		begin
			set @where_clause = @where_clause +' AND MapId in ('+cast(@map_id as nvarchar(max))+')';
		end
		if(@attempt_id is not null)
		begin
			
			set @where_clause += ' AND AttemptId = '+cast(@attempt_id as varchar);
		end

		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status') or (@filter_col = 'CallResult') or (@filter_col = 'AgentId'))  
		begin	
				if(@filter_col = 'Status' or @filter_col = 'AgentId')
				begin		
			      set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			    end
				if(@filter_col = 'CallResult')
				begin		
			      set @where_clause = @where_clause +' AND ilt.'+@filter_col + ' = '+cast(@filter_by as varchar);
			    end
		end
		if(@wrapupData is not null or @wrapupData != '' or @wrapupData != 'null')
		begin
		set @sub_count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+' ilt (nolock) inner join ' + 'Call_Result_Table_'+cast(@campaign_id as varchar)+ ' cr (nolock) on ilt.ImportList_Id=cr.ImportList_Id ';
		set @sub_where_clasue += ' cr.WrapupData = '''+@wrapupData+''' AND '  
		end		
		--begin
		--	set @where_clause = ' WHERE ' + @where_clause;
		--end
		if(@wrapupData is null or @wrapupData = '' or @wrapupData = 'null')
		begin
		set @where_clause = ' WHERE ' + @where_clause;
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
        set @main_query = 'with CallResultData as (
select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult
from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr (nolock)
right join '+ @table_name+'  ilt (nolock) on ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + ' 
)
,
outertest as
 (
select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,
crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,
il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status, 
crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,
crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts
from CallResultData crd (nolock) inner join '+ @table_name+' il (nolock) on crd.Id = il.ImportList_Id
where crd.CallResultRowNumber = 1   
)
select  ot.Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,
ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status, 
ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,
ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts   
from outertest ot (nolock)
where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'

end		
		else
		begin
		--set @where_clause =  + @where_clause + @sub_where_clasue;
		set @where_clause = ' WHERE ' + @where_clause;
		set @sub_count_query = @sub_count_query + @where_clause ;
		set @sub_count_query += 'AND  cr.WrapupData = '''+@wrapupData+''' '
		execute sp_executesql @sub_count_query, N'@total_records int output',@total_records output;
		set @main_query = 'with CallResultData as (
select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult
from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr (nolock)
right join '+ @table_name+'  ilt (nolock) on ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + ' 
)
,
outertest as
 (
select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,
crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,
il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status, 
crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,
crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts
from CallResultData crd (nolock) inner join '+ @table_name+' il (nolock) on crd.Id = il.ImportList_Id
where crd.CallResultRowNumber = 1   AND  crd.WrapupData = '''+@wrapupData+'''
)
select   ot.Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,
ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status, 
ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,
ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts   
from outertest ot (nolock)
where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'; 
		end
		exec(@main_query);	
		--select(@main_query);
		--print(@main_query);	
	end
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportListNew_Backup_08/11/2023]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_GetImportListNew_Backup_08/11/2023] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id nvarchar(max) = null,@attempt_id int = null,@wrapupData nvarchar(40) = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		declare @sub_where_clasue nvarchar(max);
		declare @sub_count_query nvarchar(max);
		set @table_name='Import_List_Table_'+cast(@campaign_id as varchar);
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+ ' ilt';
		set @where_clause = ' 1=1  ';
		set @sub_where_clasue= ' ';
		if(@map_id is not null)
		begin
			set @where_clause = @where_clause +' AND MapId in ('+cast(@map_id as nvarchar(max))+')';
		end
		if(@attempt_id is not null)
		begin
			
			set @where_clause += ' AND AttemptId = '+cast(@attempt_id as varchar);
		end

		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status') or (@filter_col = 'CallResult') or (@filter_col = 'AgentId'))  
		begin	
				if(@filter_col = 'Status' or @filter_col = 'AgentId')
				begin		
			      set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			    end
				if(@filter_col = 'CallResult')
				begin		
			      set @where_clause = @where_clause +' AND ilt.'+@filter_col + ' = '+cast(@filter_by as varchar);
			    end
		end
		if(@wrapupData is not null or @wrapupData != '' or @wrapupData != 'null')
		begin
		set @sub_count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+' ilt inner join ' + 'Call_Result_Table_'+cast(@campaign_id as varchar)+ ' cr on ilt.ImportList_Id=cr.ImportList_Id ';
		set @sub_where_clasue += ' cr.WrapupData = '''+@wrapupData+''' AND '  
		end		
		--begin
		--	set @where_clause = ' WHERE ' + @where_clause;
		--end
		if(@wrapupData is null or @wrapupData = '' or @wrapupData = 'null')
		begin
		set @where_clause = ' WHERE ' + @where_clause;
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
        set @main_query = 'with CallResultData as (
select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult
from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr 
right join '+ @table_name+'  ilt on ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + ' 
)
,
outertest as
 (
select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,
crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,
il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status, 
crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,
crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts
from CallResultData crd inner join '+ @table_name+' il on crd.Id = il.ImportList_Id
where crd.CallResultRowNumber = 1   
)
select  ot.Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,
ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status, 
ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,
ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts   
from outertest ot
where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'

end		
		else
		begin
		--set @where_clause =  + @where_clause + @sub_where_clasue;
		set @where_clause = ' WHERE ' + @where_clause;
		set @sub_count_query = @sub_count_query + @where_clause ;
		set @sub_count_query += 'AND  cr.WrapupData = '''+@wrapupData+''' '
		execute sp_executesql @sub_count_query, N'@total_records int output',@total_records output;
		set @main_query = 'with CallResultData as (
select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult
from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr 
right join '+ @table_name+'  ilt on ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + ' 
)
,
outertest as
 (
select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,
crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,
il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status, 
crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,
crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts
from CallResultData crd inner join '+ @table_name+' il on crd.Id = il.ImportList_Id
where crd.CallResultRowNumber = 1   AND  crd.WrapupData = '''+@wrapupData+'''
)
select   ot.Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,
ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status, 
ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,
ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts   
from outertest ot
where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'; 
		end
		exec(@main_query);	
		--select(@main_query);
		--print(@main_query);	
	end
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportListNew_Latest]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
CREATE	 procedure [dbo].[SP_GetImportListNew_Latest] 
						@tenant_id int, @campaign_id int,
						@page_no int, @records_per_page int,
						@map_id nvarchar(max) = null, @attempt_id int = null, @wrapupData nvarchar(40) = null, @filter_col nvarchar(100) = null,@filter_by int = null,			  
						@total_records int output    
as 
begin
set nocount on;
	if(dbo.TenantState(@tenant_id) = 1)    
	begin    
	declare @count_query nvarchar(max);    
	declare @main_query nvarchar(max);    
	declare @where_clause nvarchar(max);    
	declare @table_name nvarchar(max);    
	declare @sub_where_clasue nvarchar(max);    
	declare @sub_count_query nvarchar(max);    
	set @table_name='Import_List_Table_'+cast(@campaign_id as varchar);    
	set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+ ' ilt (nolock)';    
	set @where_clause = ' 1=1  ';    
	set @sub_where_clasue= ' ';   
	

	if(@map_id is not null)    
	begin    
		set @where_clause = @where_clause +' AND MapId IN ('+cast(@map_id as nvarchar(max))+')';    
	end    

	IF(@attempt_id IS NOT NULL)    
	begin    
		SET @where_clause += ' AND AttemptId = '+cast(@attempt_id as varchar);    
	end    
    
	IF(@filter_col IS NOT NULL AND @filter_by IS NOT NULL AND (@filter_col = 'Status') OR (@filter_col = 'CallResult') OR (@filter_col = 'AgentId'))      
	begin     
		if(@filter_col = 'Status' or @filter_col = 'AgentId')    
		begin      
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);    
       end    
		if(@filter_col = 'CallResult')    
		begin      
			SET @where_clause = @where_clause +' AND ilt.'+@filter_col + ' = '+cast(@filter_by as varchar);    
        END    
    END  
	
	IF(@wrapupData is not null or @wrapupData != '' or @wrapupData != 'null')    
	BEGIN    
		 set @sub_count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+' ilt (nolock) inner join ' + 'Call_Result_Table_'+cast(@campaign_id as varchar)+ ' cr (nolock) on ilt.ImportList_Id=cr.ImportList_Id ';    
         set @sub_where_clasue += ' cr.WrapupData = '''+@wrapupData+''' AND '      
    END      
  
    if(@wrapupData is null or @wrapupData = '' or @wrapupData = 'null')    
    begin    
        set @where_clause = ' WHERE ' + @where_clause;    
        set @count_query = @count_query + @where_clause;    
        execute sp_executesql @count_query, N'@total_records int output',@total_records output;    
  
       set @main_query = 'with CallResultData as (    
                        select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, 
						ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, 
						cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult    
						from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr (nolock)     
						right join '+ @table_name+'  ilt (nolock) on ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + '),    
						outertest as (    
					    select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,    
						crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,    
						il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status,     
						crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts, crd.WrapupData,crd.CallDateTime,    
						il.Language, il.VIN, il.ChassisNumber, il.SurveyTrackerSFID, il.DealerCode, il.ServiceName, il.ModelDesc, il.BillDate, il.City, il.ConsAddress, il.C_Dealer,  
						il.D_DealerCity, il.Zone, il.Tagging, il.Region, il.LOB, il.UserData01, il.UserData02, il.UserData03, il.UserData04, il.UserData05,    
						case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts    
						from CallResultData crd (nolock) inner join '+ @table_name+' il (nolock) on crd.Id = il.ImportList_Id   ) 
						
						select  ot.Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,    
								ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status,     
								ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,    
								ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts,  
								ot.Language, ot.VIN, ot.ChassisNumber, ot.SurveyTrackerSFID, ot.DealerCode, ot.ServiceName, ot.ModelDesc, ot.BillDate, 
								ot.City, ot.ConsAddress, ot.C_Dealer,  ot.D_DealerCity, ot.Zone, ot.Tagging, ot.Region, ot.LOB, ot.UserData01, ot.UserData02, 
								ot.UserData03, ot.UserData04, ot.UserData05  
						FROM outertest ot (nolock) WHERE RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
												AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'    
    
	end      
    else    
    begin    
		set @where_clause = ' WHERE ' + @where_clause;    
		set @sub_count_query = @sub_count_query + @where_clause ;    
		set @sub_count_query += 'AND  cr.WrapupData = '''+@wrapupData+''' '    
		execute sp_executesql @sub_count_query, N'@total_records int output',@total_records output;    
		set @main_query = 'WITH CallResultData AS (    
							SELECT ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) AS RowNumber,
							ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, 
							cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult    
							FROM Call_Result_Table_'+cast(@campaign_id as varchar)+' cr (nolock) RIGHT JOIN '+ @table_name+'  ilt (nolock) ON ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + '),    
							outertest AS (    
										SELECT ROW_NUMBER() OVER (order by il.ImportList_Id asc) AS RowNumbercount,    
											   crd.RowNumber, crd.CallResultRowNumber, il.ImportList_Id as Id, il.Phone01, il.ImportList_Id as AccountNumber, 
											   il.Phone02, il.Phone03, il.Phone04, il.Phone05, il.Phone06, il.Phone07, il.Phone08, il.Phone09, il.Phone10, 
											   il.FirstName,il.LastName, il.Status, crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,    
											   crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts    
										FROM CallResultData crd (nolock) INNER JOIN '+ @table_name+' il (nolock) ON crd.Id = il.ImportList_Id    
										WHERE crd.WrapupData = '''+@wrapupData+''' )    
  
							SELECT ot.Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,    
							ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status,     
							ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,    
							ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts       
							from outertest ot (nolock)    
							where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';     
    end   
  exec(@main_query);     
  --select(@main_query);    
  print(@main_query);     
 end    
END    


GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportListNew1]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetImportListNew1] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id nvarchar(max) = null,@attempt_id int = null,@wrapupData nvarchar(40) = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		declare @sub_where_clasue nvarchar(max);
		declare @sub_count_query nvarchar(max);
		set @table_name='Import_List_Table_'+cast(@campaign_id as varchar);
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name;
		set @where_clause = ' 1=1  ';
		set @sub_where_clasue= ' ';
		if(@map_id is not null)
		begin
			set @where_clause = @where_clause +' AND MapId in ('+cast(@map_id as varchar)+')';
		end
		if(@attempt_id is not null)
		begin
			
			set @where_clause += ' AND AttemptId = '+cast(@attempt_id as varchar);
		end

		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status') or (@filter_col = 'CallResult') or (@filter_col = 'AgentId'))  
		begin					
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@wrapupData is not null or @wrapupData != '' or @wrapupData != 'null')
		begin
		set @sub_count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+' IL inner join ' + 'Call_Result_Table_'+cast(@campaign_id as varchar)+ ' CR on IL.ImportList_Id=CR.ImportList_Id ';
		set @sub_where_clasue += ' CR.WrapupData = '''+@wrapupData+''' AND '  
		end		
		begin
			set @where_clause = ' WHERE ' + @where_clause;
		end
		if(@wrapupData is null or @wrapupData = '' or @wrapupData = 'null')
		begin
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
        set @main_query = 'with CallResultData as (
select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult
from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr 
right join '+ @table_name+'  ilt on ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + ' 
)
,
outertest as
 (
select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,
crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,
il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status, 
crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,
crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts
from CallResultData crd inner join '+ @table_name+' il on crd.Id = il.ImportList_Id
where crd.CallResultRowNumber = 1   
)
select  ot.RowNumbercount, ot.RowNumber,ot.CallResultRowNumber,ot. Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,
ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status, 
ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,
ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts   
from outertest ot
where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'

end		
		else
		begin
		set @sub_count_query = @sub_count_query + @where_clause ;
		set @sub_count_query += 'AND  CR.WrapupData = '''+@wrapupData+''' '
		execute sp_executesql @sub_count_query, N'@total_records int output',@total_records output;
		set @main_query = 'with CallResultData as (
select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult
from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr 
right join '+ @table_name+'  ilt on ilt.ImportList_Id = cr.ImportList_Id '+ @sub_count_query + ' 
)
,
outertest as
 (
select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,
crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,
il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status, 
crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,
crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts
from CallResultData crd inner join '+ @table_name+' il on crd.Id = il.ImportList_Id
where crd.CallResultRowNumber = 1   
)
select  ot.RowNumbercount, ot.RowNumber,ot.CallResultRowNumber,ot. Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,
ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status, 
ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,
ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts   
from outertest ot
where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'; 
		end
		exec(@main_query);	
		--select(@main_query);
		--print(@main_query);	
	end
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportListNew11]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetImportListNew11] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id nvarchar(4000) = null,@attempt_id int = null,@wrapupData nvarchar(40) = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		declare @sub_where_clasue nvarchar(max);
		declare @sub_count_query nvarchar(max);
		set @table_name='Import_List_Table_'+cast(@campaign_id as varchar);
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+ ' ilt';
		set @where_clause = ' 1=1  ';
		set @sub_where_clasue= ' ';
		if(@map_id is not null)
		begin
			set @where_clause = @where_clause +' AND MapId in ('+cast(@map_id as varchar)+')';
		end
		if(@attempt_id is not null)
		begin
			
			set @where_clause += ' AND AttemptId = '+cast(@attempt_id as varchar);
		end

		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status') or (@filter_col = 'CallResult') or (@filter_col = 'AgentId'))  
		begin	
				if(@filter_col = 'Status' or @filter_col = 'AgentId')
				begin		
			      set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
			    end
				if(@filter_col = 'CallResult')
				begin		
			      set @where_clause = @where_clause +' AND ilt.'+@filter_col + ' = '+cast(@filter_by as varchar);
			    end
		end
		if(@wrapupData is not null or @wrapupData != '' or @wrapupData != 'null')
		begin
		set @sub_count_query = 'select @total_records = COUNT(*) FROM '+ @table_name+' ilt inner join ' + 'Call_Result_Table_'+cast(@campaign_id as varchar)+ ' cr on ilt.ImportList_Id=cr.ImportList_Id ';
		set @sub_where_clasue += ' cr.WrapupData = '''+@wrapupData+''' AND '  
		end		
		--begin
		--	set @where_clause = ' WHERE ' + @where_clause;
		--end
		if(@wrapupData is null or @wrapupData = '' or @wrapupData = 'null')
		begin
		set @where_clause = ' WHERE ' + @where_clause;
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
        set @main_query = 'with CallResultData as (
select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult
from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr 
right join '+ @table_name+'  ilt on ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + ' 
)
,
outertest as
 (
select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,
crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,
il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status, 
crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,
crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts
from CallResultData crd inner join '+ @table_name+' il on crd.Id = il.ImportList_Id
where crd.CallResultRowNumber = 1   
)
select  ot.Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,
ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status, 
ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,
ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts   
from outertest ot
where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'

end		
		else
		begin
		--set @where_clause =  + @where_clause + @sub_where_clasue;
		set @where_clause = ' WHERE '+ @sub_where_clasue + @where_clause;
		set @sub_count_query = @sub_count_query + @where_clause ;
		set @sub_count_query += 'AND  CR.WrapupData = '''+@wrapupData+''' '
		execute sp_executesql @sub_count_query, N'@total_records int output',@total_records output;
		set @main_query = 'with CallResultData as (
select ROW_NUMBER() OVER (order by ilt.ImportList_Id asc) as RowNumber, ROW_NUMBER() OVER (partition by ilt.ImportList_Id order by cr.CallDateTime desc) as CallResultRowNumber, cr.RecordId, ilt.ImportList_Id as Id,cr.WrapupData,cr.CallDateTime,cr.CallResult
from Call_Result_Table_'+cast(@campaign_id as varchar)+' cr 
right join '+ @table_name+'  ilt on ilt.ImportList_Id = cr.ImportList_Id '+ @where_clause + ' 
)
,
outertest as
 (
select ROW_NUMBER() OVER (order by il.ImportList_Id asc) as RowNumbercount,
crd.RowNumber,crd.CallResultRowNumber,il.ImportList_Id as Id, il.Phone01,il.ImportList_Id as AccountNumber,il.Phone02,il.Phone03,il.Phone04,il.Phone05,
il.Phone06,il.Phone07,il.Phone08,il.Phone09, il.Phone10, il.FirstName,il.LastName, il.Status, 
crd.CallResult, il.AgentName,il.CreatedOn,il.ImportDateTime, il.AttemptsMade as DialAttempts,
crd.WrapupData,crd.CallDateTime, case when il.ImportAttempts > 0 then il.ImportAttempts -1 else il.ImportAttempts end as ReChurnAttempts
from CallResultData crd inner join '+ @table_name+' il on crd.Id = il.ImportList_Id
where crd.CallResultRowNumber = 1   
)
select   ot.Id, ot.Phone01,ot.AccountNumber,ot.Phone02,ot.Phone03,ot.Phone04,ot.Phone05,
ot.Phone06,ot.Phone07,ot.Phone08,ot.Phone09, ot.Phone10, ot.FirstName,ot.LastName, ot.Status, 
ot.CallResult, ot.AgentName,ot.CreatedOn,ot.ImportDateTime, ot.DialAttempts,
ot.WrapupData,ot.CallDateTime, ot.ReChurnAttempts   
from outertest ot
where RowNumbercount BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')'; 
		end
		--exec(@main_query);	
		select(@main_query);
		print(@main_query);	
	end
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportListPreviewCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[SP_GetImportListPreviewCampaign] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id int = null,@attempt_id int = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		set @table_name='PreviewCampaignImportList';
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name;
		set @where_clause = ' Where CampaignId = '+cast(@campaign_id as varchar);
		if(@map_id is not null)
		begin
			set @where_clause += 'AND MapId = '+cast(@map_id as varchar);
		end
		if(@attempt_id is not null)
		begin
			set @where_clause += 'AND AttemptId = '+cast(@attempt_id as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status') or (@filter_col = 'CallResult') or (@filter_col = 'AgentId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'With ImportList as (
							SELECT ROW_NUMBER() OVER(ORDER BY DateTime DESC) AS RowNumber, * from '+ @table_name  
							+ @where_clause + ') SELECT ID as Id,PhoneNumber,* from ImportList WHERE RowNumber BETWEEN 
							(('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
		return;
	end
		set @total_records = 0;
END








GO
/****** Object:  StoredProcedure [dbo].[SP_GetImportMultiList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[SP_GetImportMultiList] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id int = null,@attempt_id int = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		set @table_name='Import_MultiList_'+cast(@tenant_id as varchar);
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name;
		set @where_clause = ' Where CampaignId = '+cast(@campaign_id as varchar);
		if(@map_id is not null)
		begin
			set @where_clause += 'AND MapId = '+cast(@map_id as varchar);
		end
		if(@attempt_id is not null)
		begin
			set @where_clause += 'AND AttemptId = '+cast(@attempt_id as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status') or (@filter_col = 'CallResult'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'With ImportList as (
							SELECT ROW_NUMBER() OVER(ORDER BY DateTime DESC) AS RowNumber, * from '+ @table_name  
							+ @where_clause + ') SELECT ImportList_Id as Id,Phone01,AccountNumber,FirstName,LastName,Phone02,Phone03,Phone04,Phone05,Phone06,Phone07,Phone08,Phone09,Phone10,Status,CallResult,DateTime,ImportDateTime from ImportList WHERE RowNumber BETWEEN 
							(('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
		return;
	end
		set @total_records = 0;
END
















GO
/****** Object:  StoredProcedure [dbo].[SP_GetInActiveDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_GetInActiveDealer]  as begin
	select * from Dealer WHERE Status = 11 and IsActive=1;
 end







GO
/****** Object:  StoredProcedure [dbo].[SP_GetListWiseStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetListWiseStatus] 
	@campaign_id int,
	@page_no int = 1,
	@records_per_page int = 10,
	@search_term nvarchar(255) = null,
	@total_records int output
as begin
		declare @sql nvarchar(MAX);
		declare @count_query nvarchar(MAX);
		declare @inner_where_clause nvarchar(MAX);
		declare @group_by_clause nvarchar(MAX);
		set @sql = '
			With ListStats as (
				select 
					ROW_NUMBER() OVER (ORDER BY  map.DialingPriority desc) as RowNumber,
					list.Name,
					map.ListId,
					map.CampaignId,
					map.DialingPriority,
					sum(attempt.TotalRecords) as TotalRecords, 
					sum(attempt.TotalRecordImported) as ImportedRecords,
					sum(attempt.TotalDncFiltered) as ExcludedRecords,
					sum(attempt.TotalDuplicateFiltered) as DuplicateRecords,
					sum(attempt.TotalInvalid) as InvalidRecords	  
				from CampaignContact_List(readpast) map 
				left join ContactList_ImportStatus(readpast) attempt on attempt.ListId = map.CampaignList_Id
				inner join Contact_List(readpast) list on list.Id = map.ListId
				inner join ImportList_Source(readpast) source on source.Id = list.SourceId
				inner join Dealer dealer on dealer.DealerId = list.DealerId
			
		';
		set @inner_where_clause = 'where list.IsActive = 1 and source.IsActive = 1 and dealer.IsActive = 1 and (attempt.Status not in (8) or attempt.Status is null) and map.Status not in (8) and CampaignId = @campaign_id';
		if(@search_term is not null)
		begin
			set @inner_where_clause += ' and list.Name like @search_term ';
		end
		set @group_by_clause = ' group by map.CampaignId, map.ListId,list.Name,map.DialingPriority ';
		set @sql += @inner_where_clause + @group_by_clause+ ' )';
		set @count_query = @sql+' select @total_records = count(1) from ListStats;';
		
		set @sql += 'select ListId,Name as ListName,CampaignId,DialingPriority,coalesce(TotalRecords,0) as TotalRecords,coalesce(ImportedRecords,0) as ImportedRecords, coalesce(ExcludedRecords,0) as ExcludedRecords,coalesce(DuplicateRecords,0) as DuplicateRecords,coalesce(InvalidRecords,0) as InvalidRecords from ListStats WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		
		execute sp_executesql @count_query, N'@campaign_id int,@search_term nvarchar(250),@total_records int output', @campaign_id,@search_term,@total_records output ;

		execute sp_executesql @sql, N'@campaign_id int,@search_term nvarchar(250)',@campaign_id,@search_term;

end




GO
/****** Object:  StoredProcedure [dbo].[SP_GetListWiseStatusThreshold]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetListWiseStatusThreshold] 
	@campaign_id int,
	@page_no int = 1,
	@records_per_page int = 10,
	@search_term nvarchar(255) = null,
	@total_records int output
as begin
		declare @sql nvarchar(MAX);
		declare @count_query nvarchar(MAX);
		declare @inner_where_clause nvarchar(MAX);
		declare @group_by_clause nvarchar(MAX);
		set @sql = '
			With ListStats as (
				select 
					ROW_NUMBER() OVER (ORDER BY  CMG.ListId desc) as RowNumber,
					list.Name,
					CMG.ListId,
					CMG.CampaignId,
					CMG.CreatedOn
				from ContactMapGroup(readpast) CMG
				inner join Contact_List(readpast) list on list.Id = CMG.ListId				
				inner join Dealer dealer on dealer.DealerId = list.DealerId
			
		';
		set @inner_where_clause = 'where list.IsActive = 1 and dealer.IsActive = 1 and CampaignId = @campaign_id and CMG.Status in (1,2) ';
		if(@search_term is not null)
		begin
			set @inner_where_clause += ' and list.Name like @search_term ';
		end
		set @group_by_clause = ' group by CMG.CampaignId, CMG.ListId,list.Name,CMG.CreatedOn';
		set @sql += @inner_where_clause + @group_by_clause+ ' )';
		set @count_query = @sql+' select @total_records = count(1) from ListStats;';
		
		set @sql += 'select ListId,Name as ListName,CampaignId from ListStats WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		
		execute sp_executesql @count_query, N'@campaign_id int,@search_term nvarchar(250),@total_records int output', @campaign_id,@search_term,@total_records output ;

		execute sp_executesql @sql, N'@campaign_id int,@search_term nvarchar(250)',@campaign_id,@search_term;

end





GO
/****** Object:  StoredProcedure [dbo].[SP_GetMapIdDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_GetMapIdDealer] @DealerId int as begin
	select MapId from  DealerExtraDetails where   IsActive=1 and  DealerId = @DealerId
 end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetMapsWithPriority]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_GetMapsWithPriority]
@campaign_id int
as begin
select CampaignList_Id as Id,map.DialingPriority from CampaignContact_List map inner join Contact_List cl on map.ListId=cl.Id inner join Dealer d on cl.DealerId=d.DealerId  where map.IsActive = 1 and d.IsActive = 1  and cl.IsActive = 1 and map.Status not in (12,9,6,8) and CampaignId  = @campaign_id order by DialingPriority asc
END






GO
/****** Object:  StoredProcedure [dbo].[SP_GetMapWiseStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetMapWiseStatus] 
	@campaign_id int,
	@list_id int,
	@dialing_priority int,
	@page_no int,
	@records_per_page int,
	@total_records int output
as begin
		declare @sql nvarchar(MAX);
		declare @count_query nvarchar(MAX);
		declare @inner_where_clause nvarchar(MAX);
		declare @group_by_clause nvarchar(MAX);
		set @sql = '
			With ListStats as (
				select 
					ROW_NUMBER() OVER (ORDER BY map.DialingPriority asc) as RowNumber,
					list.Name,
					map.ListId,
					map.CampaignId,
					map.CampaignList_Id as MapId,
					map.DialingPriority,
					sum(attempt.TotalRecords) as TotalRecords, 
					sum(attempt.TotalRecordImported) as ImportedRecords,
					sum(attempt.TotalDncFiltered) as ExcludedRecords,
					sum(attempt.TotalDuplicateFiltered) as DuplicateRecords,
					sum(attempt.TotalInvalid) as InvalidRecords,	  
					map.Status,
					map.CreatedOn
				from CampaignContact_List map 
				left join ContactList_ImportStatus attempt on attempt.ListId = map.CampaignList_Id
				inner join Contact_List list on list.Id = map.ListId
				inner join ImportList_Source source on source.Id = list.SourceId
				inner join Dealer dealer on dealer.DealerId = list.DealerId
			
		';
		set @inner_where_clause = 'where list.IsActive = 1 and source.IsActive = 1 and dealer.IsActive = 1 and (attempt.Status is null or attempt.Status not in (8)) and map.Status not in (8) and map.CampaignId = @campaign_id and map.ListId = @list_id and map.DialingPriority = @dialing_priority';
		
		set @group_by_clause = ' group by map.CampaignId, map.ListId,list.Name,map.DialingPriority,map.CampaignList_Id,map.Status,map.CreatedOn';
		set @sql += @inner_where_clause + @group_by_clause+ ')';
		set @count_query = @sql+' select @total_records = count(1) from ListStats';
		
		set @sql += 'select MapId,ListId,Name as ListName,CampaignId,DialingPriority,coalesce(TotalRecords,0) as TotalRecords,coalesce(ImportedRecords,0) as ImportedRecords,coalesce(ExcludedRecords,0) as ExcludedRecords,coalesce(DuplicateRecords,0) as DuplicateRecords,coalesce(InvalidRecords,0) as InvalidRecords,Status,CreatedOn from ListStats WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		
		execute sp_executesql @count_query, N'@campaign_id int,@list_id int,@dialing_priority int,@total_records int output', @campaign_id,@list_id,@dialing_priority,@total_records output ;

		execute sp_executesql @sql, N'@campaign_id int,@list_id int,@dialing_priority int',@campaign_id,@list_id,@dialing_priority;
end




GO
/****** Object:  StoredProcedure [dbo].[SP_GetMultiContactList_ImportStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[SP_GetMultiContactList_ImportStatus] @tenant_id int,@map_id int = null, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @sort_col nvarchar(100) = null, @sort_direction nvarchar(10) = 'desc', @total_records int output
as begin
	
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM MultiContactList_ImportStatus ';
		set @where_clause = 'WHERE ListId in (select MultiListId from MultiContactListConfig where TenantId =' +CAST(@tenant_id as varchar)+')';
		if(@map_id is not null)
		begin
			set @where_clause += 'AND ListId = '+cast(@map_id as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and ((@filter_col = 'ListId') or (@filter_col = 'CampaignId')))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_ContactList_MultiImportStatus AS (SELECT ROW_NUMBER() OVER(ORDER BY CampaignList_Id DESC) AS RowNumber ,* FROM MultiContactList_ImportStatus ' + @where_clause + ') SELECT * FROM All_ContactList_MultiImportStatus WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';	
		if(@sort_col is not null and (@sort_col = 'LastAttemptedOn' or @sort_col = 'LastUpdatedOn' or @sort_col = 'CreatedOn'))
		begin
			set @main_query = @main_query + ' ORDER BY '+@sort_col + ' '+@sort_direction;
		end
		exec(@main_query)
	end
	else
		set @total_records = 0;
END




















GO
/****** Object:  StoredProcedure [dbo].[SP_GetMultiContactListImportStatusById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetMultiContactListImportStatusById] @id int
as begin
	select * from MultiContactList_ImportStatus where CampaignList_Id = @id
end













GO
/****** Object:  StoredProcedure [dbo].[SP_GetPreProcessedLists]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetPreProcessedLists] @tenant_id int, @batch_size int, @request_type nvarchar(25) as
begin
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @dynamicSql nvarchar(MAX);
		set @dynamicSql = 'select top '+CAST(@batch_size as nvarchar)+' * from CampaignContact_List cl ';
		set @dynamicSql = @dynamicSql + 'inner join Contact_List list on cl.ListId=list.Id inner join Dealer d on list.DealerId=d.DealerId  where d.IsActive = 1  and cl.TenantId = @tenant_id and dbo.ListState(cl.ListId) = 1 and cl.IsActive = 1 and cl.Status = 7 and cl.RequestType =@request_type ;';
		execute sp_executesql @dynamicSql, N'@tenant_id int, @request_type nvarchar(25)', @tenant_id,@request_type
	end
end




select * from CampaignContact_List;










GO
/****** Object:  StoredProcedure [dbo].[SP_GetPreviewCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetPreviewCampaign] @campaign_id int as
begin
	select * from PreviewCampaign where  PreviewCampaignId= @campaign_id and IsActive = 1
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetPreviewCampaignList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[SP_GetPreviewCampaignList] 
	@tenant_id int, 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM PreviewCampaign';
		set @where_clause = ' Where IsActive =1 and TenantId = '+cast(@tenant_id as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Name'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
set @main_query ='WITH All_PCampaigns AS(SELECT ROW_NUMBER() OVER(ORDER BY pc.PreviewCampaignId DESC) AS RowNumber ,pc.* FROM PreviewCampaign pc  ' + @where_clause + ') SELECT *  FROM All_PCampaigns WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';

		exec(@main_query);

	end
	else
		set @total_records = 0;
end













GO
/****** Object:  StoredProcedure [dbo].[SP_GetPreviewCampListByAgent]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetPreviewCampListByAgent] @agent_id nvarchar(255)=null,@agent_loginName nvarchar(255)=null, 
@total_records int output
as 
begin
if(dbo.TenantState(1000)=1)
begin 
declare @campaign_details nvarchar(max);
declare @where_clause nvarchar(max);
declare @joint_clause nvarchar(max);
declare @final_query nvarchar(max);
declare @main_query nvarchar(max);
declare @assignedData_result nvarchar(max);
DECLARE @query nvarchar(MAX)
set @campaign_details = 'select @total_records = COUNT(*) from PreviewCampaign'; 
set @where_clause = 'StartDate <=GETDATE() and EndDate >=GETDATE()';
if(@agent_id is not null)
		begin
			set @joint_clause =	'StartTime <=CONVERT(VARCHAR(20), GETDATE(), 114) and EndTime >=CONVERT(VARCHAR(20), GETDATE(), 114) and State=1 and IsActive =1 and AgentId='''+ @agent_id+''';'
		end
		else
		begin
		set @joint_clause =	'StartTime <=CONVERT(VARCHAR(20), GETDATE(), 114) and EndTime >=CONVERT(VARCHAR(20), GETDATE(), 114) and State=1 and IsActive =1 and AgentLoginName='''+ @agent_loginName+''';' 
		end
set @main_query = @campaign_details +' WHERE '+ @where_clause;  
set @final_query= @main_query + ' AND '+ @joint_clause;
execute sp_executesql @final_query, N'@total_records int output',@total_records output;
IF(@total_records >0)
begin 
if(@agent_id is not null)
begin
set @assignedData_result = 'Select * from PreviewCampaignImportList where Status=2 and AgentId=''' + @agent_id +''';'
exec(@assignedData_result);
end
else
begin 
set @assignedData_result = 'Select * from PreviewCampaignImportList where Status=2 and AgentLoginName=''' + @agent_loginName +''';'
exec(@assignedData_result);
end
end 
else
set @total_records = 0;
end
end
















GO
/****** Object:  StoredProcedure [dbo].[SP_GetPreviewImportContactById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetPreviewImportContactById] @Id int as 
begin

select * from [dbo].[PreviewCampaignImportList] where [ID]=@Id
end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetPreviewSkillMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[SP_GetPreviewSkillMap] 
	@dealer_id int, 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@total_records int output
as begin

	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM SkillGroupMap';
		set @where_clause = ' Where DealerId = '+cast(@dealer_id as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'PreviewCampaignId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
set @main_query ='WITH All_MapSkills AS(SELECT ROW_NUMBER() OVER(ORDER BY pc.SkillMapId DESC) AS RowNumber ,pc.* FROM SkillGroupMap pc  ' + @where_clause + ') SELECT *  FROM All_MapSkills WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';

		exec(@main_query);
	end

end














GO
/****** Object:  StoredProcedure [dbo].[SP_GetPreviewWrapUpListData]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetPreviewWrapUpListData] @tenant_id int, @dealer_id int,@page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin
	if(dbo.TenantState(1000) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM PreviewWarpReasonCode PWRC';
		set @where_clause = ' WHERE PWRC.IsActive = 1 AND DealerId ='+ CAST(@dealer_id as varchar(100)) ;
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_PreviewWrapUpCode AS (SELECT ROW_NUMBER() OVER(ORDER BY PWRC.WrapupCodeId DESC) AS RowNumber ,PWRC.* FROM PreviewWarpReasonCode PWRC ' + @where_clause + ') SELECT * FROM All_PreviewWrapUpCode WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
		end
	else
		set @total_records = 0;
END










GO
/****** Object:  StoredProcedure [dbo].[SP_GetRealTimeListDialingStatsByCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetRealTimeListDialingStatsByCampaign]
	@campaignId int 
AS

BEGIN

Declare @ImportListTable AS nvarchar(30);
DECLARE @final_query AS nvarchar(max);
SET @ImportListTable = 'Import_List_Table_' + CONVERT(nvarchar(20), @campaignId);

SET @final_query = 'SELECT map.CampaignId, map.ListId, map.CampaignList_Id as MapId, attempt.TotalRecords, attempt.TotalRecordImported 
FROM CampaignContact_List map 
JOIN ContactList_ImportStatus attempt on map.CampaignList_Id = attempt.ListId
JOIN ' + @ImportListTable + ' ilt on ilt.MapId = map.CampaignList_Id';

exec(@final_query);
print(@final_query);

END


GO
/****** Object:  StoredProcedure [dbo].[SP_GetRechurnPolicyById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetRechurnPolicyById] @id int as
BEGIN
Select * from RechurnPolicy where Id=@id
  
END	





GO
/****** Object:  StoredProcedure [dbo].[SP_GetReChurnPolicyList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetReChurnPolicyList] @tenant_id int,@dealerId int, @page_no int, @records_per_page int, @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		select @total_records = COUNT(*) FROM RechurnPolicy where  DealerId = @dealerId and IsActive=1;
		WITH All_Rechurns AS
		(
			SELECT ROW_NUMBER() OVER(ORDER BY Id ASC) AS RowNumber,Id,Name,Description,Schedule,IsManual,AgentDispositionsDetailsXml,CallResultsDetailsXml,Status,CreatedOn,LastUpdatedOn,DealerId  FROM RechurnPolicy where DealerId = @dealerId and IsActive=1 and IsManual=0
		) SELECT  Id,Name,Description,Schedule,IsManual,AgentDispositionsDetailsXml,CallResultsDetailsXml,Status,CreatedOn,LastUpdatedOn,DealerId FROM All_Rechurns WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
		end
	else
		set @total_records = 0
END



GO
/****** Object:  StoredProcedure [dbo].[SP_GetReChurnPolicyListList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetReChurnPolicyListList] AS




GO
/****** Object:  StoredProcedure [dbo].[SP_GetReChurnPolicyMapList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetReChurnPolicyMapList]@campaignId int, @page_no int, @records_per_page int, @total_records int output
as begin
	
		select @total_records = COUNT(*) FROM RechurnPolicyMap where  Campaign = @campaignId and IsActive=1;
		WITH All_Rechurns AS
		(
			SELECT ROW_NUMBER() OVER(ORDER BY rpm.Id ASC) AS RowNumber,rpm.Id as Id,PolicyId as PolicyId,rpm.Campaign as Campaign,rpm.Status as Status,rpm.CreatedOn as CreatedOn,rpm.LastUpdatedOn as LastUpdatedOn,ced.Name as CampaignName,rp.Name as PolicyName,rp.IsManual as IsManual FROM RechurnPolicyMap rpm inner join CampaignExtraDetails ced on rpm.Campaign=ced.CampaignId inner join ReChurnPolicy rp on  rp.Id=rpm.PolicyId and  rpm.Campaign = @campaignId and rpm.IsActive=1 
		) SELECT  Id,PolicyId,PolicyName,IsManual,Campaign,CampaignName,Status,CreatedOn,LastUpdatedOn  FROM All_Rechurns WHERE RowNumber BETWEEN ((@page_no-1)*@records_per_page)+1 AND @records_per_page * (@page_no)
		end



GO
/****** Object:  StoredProcedure [dbo].[SP_GetRechurnPolicyScheduleById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetRechurnPolicyScheduleById] @id int as
BEGIN
Select rp.Id,rp.Name,rp.Description,rp.Schedule,rp.IsManual,rp.CallResultsDetailsXml,rp.Status,rp.CreatedOn,rp.AgentDispositionsDetailsXml,rs.Frequency,rs.RecurrenceInterval,rs.RecurrenceUnit,rs.StartDateTime,rs.EndDateTime,rs.Status,rs.NextIterationDate from RechurnPolicy rp inner join RecurrenceSchedule  rs on rp.Schedule=rs.Id  where rp.Id=@id 
END	





GO
/****** Object:  StoredProcedure [dbo].[SP_GetRecurrenceScheduleist]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetRecurrenceScheduleist]  @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @search_term nvarchar(100) = null, @total_records int output
as begin

		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM RecurrenceSchedule';
		set @where_clause = '  ';
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status'))  
		begin
			set @where_clause = 'where ' +@filter_col + ' = '+cast(@filter_by as varchar);
		end
		if(@search_term is not null)
		begin
			set @where_clause = @where_clause + ' AND Name like ''%'+@search_term+'%''';
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = '	WITH All_RecurrenceSchedules AS(SELECT ROW_NUMBER() OVER(ORDER BY Id DESC) AS RowNumber ,Id,Name,Description ,ScheduleType,Frequency,RecurrenceInterval,RecurrenceUnit,StartDateTime,EndDateTime,Status,CreatedOn,LastUpdatedOn,NextIterationDate FROM RecurrenceSchedule ' + @where_clause + ') SELECT Id,Name,Description ,ScheduleType,Frequency,RecurrenceInterval,RecurrenceUnit,StartDateTime,EndDateTime,Status,CreatedOn,LastUpdatedOn,NextIterationDate FROM All_RecurrenceSchedules WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query)
	end





GO
/****** Object:  StoredProcedure [dbo].[SP_GetRoleById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_GetRoleById] @role_id int 
as 
begin
Select * from Role_Master where RoleId=@role_id and IsActive=1 
end









GO
/****** Object:  StoredProcedure [dbo].[SP_GetScheduledLists]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetScheduledLists] @tenant_id int, @date_time datetime, @batch_size int  as
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @dynamic_sql nvarchar(MAX);
		set @dynamic_sql = 'select top '+CAST(@batch_size as nvarchar)+' * from CampaignContact_List cl ';
		set @dynamic_sql = @dynamic_sql + 'inner join Contact_List list on cl.ListId=list.Id inner join Dealer d on list.DealerId=d.DealerId  where d.IsActive = 1  and cl.TenantId = @tenant_id and dbo.ListState(cl.ListId) = 1 and cl.IsActive = 1 and  (cl.Status = 3 or cl.Status = 1) ';
		set @dynamic_sql = @dynamic_sql +' and (ScheduleStart is not null and CONVERT(date,ScheduleStart) = Convert(date,@date_time))';
		execute sp_executesql @dynamic_sql, N'@tenant_id int, @date_time datetime', @tenant_id ,@date_time
	end
end 









GO
/****** Object:  StoredProcedure [dbo].[SP_GetScheduledMultipleLists]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[SP_GetScheduledMultipleLists] @tenant_id int, @date_time datetime, @batch_size int as
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @dynamic_sql nvarchar(MAX);
		set @dynamic_sql = 'select top '+CAST(@batch_size as nvarchar)+' * from MultiContactListConfig cl ';
		set @dynamic_sql = @dynamic_sql + 'where TenantId = @tenant_id and cl.IsActive = 1 and  (Status = 3 or Status = 1) ';
		set @dynamic_sql = @dynamic_sql +' and (ScheduleStart is not null and CONVERT(date,ScheduleStart) = Convert(date,@date_time))';
		execute sp_executesql @dynamic_sql, N'@tenant_id int, @date_time datetime', @tenant_id ,@date_time
	end
end

















GO
/****** Object:  StoredProcedure [dbo].[SP_GetScheduleMailWithCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetScheduleMailWithCampaign]
AS
BEGIN
    SELECT 
        sm.CampaignId, 
        sm.FromAddress, 
        sm.ToAddress, 
        sm.SubjectLine, 
        sm.ScheduledDays, 
        sm.ScheduledTime, 
        ce.Name
    FROM 
        Schedule_Mail sm
    JOIN 
        campaignextradetails ce ON sm.CampaignId = ce.CampaignId;
END;
GO
/****** Object:  StoredProcedure [dbo].[SP_GetSessionById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetSessionById] @session_id int as begin
	select * from UniCampaignSession where SessionId = @session_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetSessions]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetSessions] @tenant_id int, @page_no int, @records_per_page int, @filter_col nvarchar(100) = null,@filter_by int = null, @sort_col nvarchar(100) = null, @sort_direction nvarchar(10) = 'desc', @total_records int output
as begin
if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM UniCampaignSession';
		set @where_clause = ' WHERE TenantId =' +CAST(@tenant_id as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'UserId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH AllSessions AS (SELECT ROW_NUMBER() OVER(ORDER BY SessionId DESC) AS RowNumber,sess.* from UniCampaignSession sess ' + @where_clause + ') SELECT * FROM AllSessions WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';	
		if(@sort_col is not null and @sort_col = 'StartDateTime')
		begin
			set @main_query = @main_query + ' ORDER BY '+@sort_col + ' '+@sort_direction;
		end
		exec(@main_query)
	end
	else
		set @total_records = 0;
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetSkillGroupBySkillGroupId]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[SP_GetSkillGroupBySkillGroupId] @Id int as begin
select * from UCCE_Skill_Group where SkillTargetID=@Id
END








GO
/****** Object:  StoredProcedure [dbo].[SP_GetSkillGroupWithNameStartWith]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure[dbo].[SP_GetSkillGroupWithNameStartWith] @startwith nvarchar(150)
as begin
select * from [dbo].[UCCE_Skill_Group] where EnterpriseName like ''+@startwith+'%';
end







GO
/****** Object:  StoredProcedure [dbo].[SP_GetSMSCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetSMSCampaign] @campaign_id int , @dealer_id int
as
begin
	select camp.*, conf.SMSConfigName as SMSConfigName from SMSCampaign camp inner join SMSConfiguration conf on camp.SMSConfigId = conf.SMSConfigId where camp.SMSCampaignId = @campaign_id and camp.IsActive = 1 and conf.IsActive = 1 and camp.DealerId = @dealer_id;
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetSMSCampaignList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetSMSCampaignList] 
	@tenant_id int, 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@total_records int output,
	@dealer_id int
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM SMSCampaign camp';
		set @where_clause = ' inner join SMSConfiguration conf on camp.SMSConfigId = conf.SMSConfigId WHERE camp.IsActive = 1 and conf.IsActive = 1 AND camp.TenantId = '+cast(@tenant_id as varchar) +' AND camp.DealerId = '+cast(@dealer_id as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Name' or @filter_col = 'SMSConfigId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH AllSMSCampaigns AS(SELECT ROW_NUMBER() OVER(ORDER BY SMSCampaignId DESC) AS RowNumber ,camp.*, conf.SMSConfigName as SMSConfigName from SMSCampaign camp ' + @where_clause + ') SELECT *  FROM AllSMSCampaigns WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
end













GO
/****** Object:  StoredProcedure [dbo].[SP_GetSMSContactMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[SP_GetSMSContactMap]
	@tenant_id int, 
	@map_id int
as begin
	select map.*,list.Name as ContactList, camp.Name as Campaign from SMSCampaign_ContactList map 
	inner join Contact_List list on map.ContactListId = list.Id
	inner join SMSCampaign camp on camp.SMSCampaignId = map.CampaignId
	where map.TenantId = @tenant_id and map.Id = @map_id and list.IsActive = 1 and camp.IsActive = 1 
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetSMSContactMapList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetSMSContactMapList] 
	@tenant_id int, 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@total_records int output 
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM SMSCampaign_ContactList map ';
		set @where_clause = 'inner join Contact_List list on map.ContactListId = list.Id inner join SMSCampaign camp on camp.SMSCampaignId = map.CampaignId ' ;
		set @where_clause = @where_clause+'WHERE map.TenantId = '+cast(@tenant_id as varchar);
		
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'CampaignId' or @filter_col = 'ContactListId' or @filter_col = 'Status'))  
		begin
			set @where_clause = @where_clause +' AND map.'+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_Maps AS(SELECT ROW_NUMBER() OVER(ORDER BY map.Id DESC) AS RowNumber ,map.*,list.Name as ContactList, camp.Name as Campaign from SMSCampaign_ContactList map ' + @where_clause + ') SELECT *  FROM All_Maps WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
	end
	else
		set @total_records = 0;
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetSMSImportList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[SP_GetSMSImportList] @tenant_id int,@campaign_id int, @page_no int, @records_per_page int,@map_id int = null,@attempt_id int = null, @filter_col nvarchar(100) = null,@filter_by int = null,  @total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		declare @table_name nvarchar(max);
		set @table_name='SMS_List_'+cast(@tenant_id as varchar);
		set @count_query = 'select @total_records = COUNT(*) FROM '+ @table_name;
		set @where_clause = ' Where CampaignId = '+cast(@campaign_id as varchar);
		if(@map_id is not null)
		begin
			set @where_clause += 'AND MapId = '+cast(@map_id as varchar);
		end
		if(@attempt_id is not null)
		begin
			set @where_clause += 'AND AttemptId = '+cast(@attempt_id as varchar);
		end
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'Status' or @filter_col='SMSResult'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'With ImportList as (
							SELECT ROW_NUMBER() OVER(ORDER BY CreatedOn DESC) AS RowNumber, * from '+ @table_name  
							+ @where_clause + ') SELECT Id,PhoneNumber,Status,SMSResult,CreatedOn,ProcessedOn from ImportList WHERE RowNumber BETWEEN 
							(('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
		return;
	end
		set @total_records = 0;
END











GO
/****** Object:  StoredProcedure [dbo].[SP_GetSMSList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetSMSList] @tenant_id int, @status int, @batch_size int as begin
	if(dbo.TenantState(@tenant_id)=1)
	begin
	declare @table_name nvarchar(100);
	set @table_name = 'SMS_List_'+cast(@tenant_id as nvarchar);
	declare  @current_time time; 
	declare @current_date date;
	set @current_time = convert(time,getdate());
	set @current_date = convert(date,getdate());
	declare @sql nvarchar(max);
	set @sql = '
		select	top '+CAST(@batch_size as nvarchar)+
			' * from '+@table_name+' where Status = '+CAST(@status as nvarchar)+
		'	and CampaignId in (SELECT SMSCampaignId from SMSCampaign where IsActive = 1 and State = 1)
			order by Id asc
		';
	execute sp_executesql @sql;
	end
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetSMSStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetSMSStatus] 
	@tenant_id int,
	@status_id int
as begin
	select st.* from SMSContactList_Status st 
			where st.Id = @status_id and st.TenantId = @tenant_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetSMSStatusList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetSMSStatusList] 
	@tenant_id int, 
	@page_no int, 
	@records_per_page int, 
	@filter_col nvarchar(100) = null,
	@filter_by int = null, 
	@sort_col nvarchar(100) = null, 
	@sort_direction nvarchar(10) = 'desc', 
	@total_records int output
as begin
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
		set @count_query = 'select @total_records = COUNT(*) FROM SMSContactList_Status ';
		set @where_clause = 'WHERE TenantId =' +CAST(@tenant_id as varchar);
		if(@filter_col is not null and @filter_by is not null and (@filter_col = 'MapId'))  
		begin
			set @where_clause = @where_clause +' AND '+@filter_col + ' = '+cast(@filter_by as varchar);
		end	
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH AllStatus AS (SELECT ROW_NUMBER() OVER(ORDER BY Id DESC) AS RowNumber ,* from SMSContactList_Status ' + @where_clause + ') SELECT * FROM AllStatus WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';	
		if(@sort_col is not null and @sort_col = 'LastAttemptedOn')
		begin
			set @main_query = @main_query + ' ORDER BY '+@sort_col + ' '+@sort_direction;
		end
		exec(@main_query)
	end
	else
		set @total_records = 0;
end











GO
/****** Object:  StoredProcedure [dbo].[SP_GetStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_GetStatus] @tenant_id int as 
begin	
	declare @job_name nvarchar(max), @tenant_id_str nvarchar(20),@destination_db nvarchar(MAX),@destination_table nvarchar(max),
			@import_table_name nvarchar(100), @call_result_table_name nvarchar(100),@email_table_name nvarchar(100),
			@email_result_table_name nvarchar(100),@sms_table_name nvarchar(100),@sms_result_table_name nvarchar(100), @linked_server nvarchar(100);
	
	set @tenant_id_str = CAST(@tenant_id as nvarchar(20));
	set @import_table_name = 'Import_List_'+@tenant_id_str;
	set @call_result_table_name = 'Call_Result_'+@tenant_id_str;
	set @email_table_name='Email_List_'+@tenant_id_str;
	set @email_result_table_name='Email_Result';
	set @sms_table_name = 'SMS_List_'+@tenant_id_str;
	set @sms_result_table_name = 'SMS_Result';
	SELECT @destination_db = DB_NAME();
	set @destination_table = 'Outbound_Call_Detail_'+@tenant_id_str
	set @job_name = @destination_db+N'_Data_Collect_'+@tenant_id_str;
	select @linked_server = LinkedServer from DataDump_LastRecoveryKey where TenantId = @tenant_id
	--select * from sys.tables where name=@import_table_name
	--select * from msdb.dbo.sysjobs where name = @job_name
	--select * from sys.servers where name = @source_server
	--select * from sys.tables where name=@destination_table
	--select * from msdb.dbo.sysschedules where name = 'UniCampaign_Job_Schedule'

	declare @linked_server_created bit, @import_list_created bit, @call_result_created bit, @email_list_created bit, @sms_list_created bit, @outbound_detail_table_created bit, @job_created bit, @job_status bit;
	set @linked_server_created = 0;
	set @import_list_created = 0;
	set @call_result_created = 0;
	set @email_list_created = 0;
	set @sms_list_created = 0;
	set @outbound_detail_table_created = 0;
	set @job_created = 0;
	set @job_status = 0;
	declare @job_id nvarchar(max);
	if(exists(select * from sys.tables where name=@import_table_name))
		set @import_list_created = 1;
	if(exists(select * from sys.tables where name=@call_result_table_name))
		set @call_result_created = 1;
	if(exists(select * from sys.tables where name = @email_table_name))
		set @email_list_created = 1;
	if(exists(select * from sys.tables where name = @sms_table_name))
		set @sms_list_created = 1;
	if(exists(select * from sys.tables where name=@destination_table))
		set @outbound_detail_table_created = 1;
	if(exists(select * from sys.servers where name = @linked_server))
		set @linked_server_created = 1;
	if(exists(select * from msdb.dbo.sysjobs where name = @job_name))
	begin
		set @job_created = 1;
		select @job_id = job_id from msdb.dbo.sysjobs where name = @job_name
		select top 1 @job_status = run_status from msdb.dbo.sysjobhistory where job_id = @job_id and step_id = 0 order by run_date desc, run_time desc
	end	
	select 
		@tenant_id as Tenant,
		@import_list_created as VoiceList, 
		@call_result_created as CallResult, 
		@outbound_detail_table_created as DialerDetail, 
		@email_list_created as EmailList,
		@sms_list_created as SmsList,
		@linked_server_created as LinkedServerCreated,
		@job_created as JobCreated,
		@job_status as JobRunStatus 
end










GO
/****** Object:  StoredProcedure [dbo].[SP_GetStuckRecords]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[SP_GetStuckRecords]
as
begin
CREATE TABLE #XMLTable (CampaignList_Id int ,attribute varchar(30), operator varchar(30) , value varchar(30) )

INSERT INTO #XMLTable (CampaignList_Id,attribute , operator , value )
SELECT
s.CampaignList_Id,
m.c.value('@attribute', 'varchar(max)') as attribute ,
m.c.value('@operator', 'varchar(max)') as operator,
m.c.value('@value', 'varchar(max)') as value
from CampaignContact_List as s
outer apply s.Filters.nodes('filter/conditions/condition') as m(c)


SELECT CCL.CampaignList_Id , CED.Name as Campaign_Name , CL.Name as List_Name ,TS.value , CLI.Lastattemptedon
from CampaignContact_List CCL
INNER JOIN Contact_List CL ON CCL.ListId=CL.Id
INNER JOIN ContactList_ImportStatus CLI ON CCL.CampaignList_Id=CLI.ListId
INNER JOIN CampaignExtraDetails CED ON CCL.CampaignId=CED.CampaignId
INNER JOIN #XMLTable TS ON CCL.CampaignList_Id=TS.CampaignList_Id
WHERE CCL.Status IN(1,5,7) and (GETUTCDATE()-CLI.LastAttemptedOn)<=15
AND CCL.IsActive=1 AND CL.IsActive=1


DROP TABLE #XMLTable
end




GO
/****** Object:  StoredProcedure [dbo].[SP_GetTenantById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetTenantById] @Id int as begin
select * from Tenants where Id=@Id
END















GO
/****** Object:  StoredProcedure [dbo].[SP_GetUnScheduledData]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE procedure [dbo].[SP_GetUnScheduledData]
	@map_id int
as begin
	select * from MultipleContactListData where MapId=@map_id and Status=1
end













GO
/****** Object:  StoredProcedure [dbo].[SP_GetUnscheduledLists]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE procedure [dbo].[SP_GetUnscheduledLists] @tenant_id int, @batch_size int  as
begin
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @dynamicSql nvarchar(MAX);
		set @dynamicSql = 'select top '+CAST(@batch_size as nvarchar)+' * from CampaignContact_List cl ';
		set @dynamicSql = @dynamicSql + ' inner join Contact_List list on cl.ListId=list.Id inner join Dealer d on list.DealerId=d.DealerId where d.IsActive = 1 and cl.TenantId = @tenant_id and dbo.ListState(cl.ListId) = 1 and cl.IsActive = 1 and (cl.Status = 1 or cl.Status = 3) and ScheduleStart is null';
		execute sp_executesql @dynamicSql, N'@tenant_id int ',@tenant_id
	end
end






GO
/****** Object:  StoredProcedure [dbo].[SP_GetUnscheduledLists_Preview]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[SP_GetUnscheduledLists_Preview] @tenant_id int, @batch_size int  as
begin
	if(dbo.TenantState(@tenant_id) = 1) 
	begin
		declare @dynamicSql nvarchar(MAX);
		set @dynamicSql = 'select top '+CAST(@batch_size as nvarchar)+' * from PreviewCampaignContact_List cl ';
		set @dynamicSql = @dynamicSql + 'where TenantId = @tenant_id and dbo.ListState(cl.ListId) = 1 and cl.IsActive = 1 and (Status = 1 or Status = 3) ;';
		execute sp_executesql @dynamicSql, N'@tenant_id int', @tenant_id
	end
end

















GO
/****** Object:  StoredProcedure [dbo].[SP_GetUnScheduledMultipleLists]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE procedure [dbo].[SP_GetUnScheduledMultipleLists] @tenant_id int, @batch_size int as
begin
	if(dbo.TenantState(@tenant_id) = 1)
	begin
		declare @dynamic_sql nvarchar(MAX);
		set @dynamic_sql = 'select top '+CAST(@batch_size as nvarchar)+' * from MultiContactListConfig cl ';
		set @dynamic_sql = @dynamic_sql + 'where TenantId = @tenant_id and cl.IsActive = 1 and  (Status = 3 or Status = 1) and ScheduleStart is null ';
		execute sp_executesql @dynamic_sql, N'@tenant_id int', @tenant_id 
	end
end












GO
/****** Object:  StoredProcedure [dbo].[SP_GetUserMasterById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_GetUserMasterById] @user_id int as
BEGIN
Select u.* ,d.DealerName as DealerName,r.Name as RoleName from User_Master u
 inner join Dealer d on u.DealerId=d.DealerId
  inner join Role_Master r on u.RoleId=r.RoleId 
  where u.UserId= @user_id and u.IsActive=1 and d.IsActive=1 and r.IsActive=1
		
END	







GO
/****** Object:  StoredProcedure [dbo].[SP_GetWrapupCodeById]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetWrapupCodeById] @WrapCodeUpId int,@DealerId Int
As begin
 select *  from PreviewWarpReasonCode  pc
 inner join Dealer d on pc.DealerId=d.DealerId
 where d.IsActive=1 and pc.DealerId=@DealerId and WrapupCodeId=@WrapCodeUpId
end








GO
/****** Object:  StoredProcedure [dbo].[SP_GetWrapUpData]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_GetWrapUpData] @tenant_id int, @campaignId int,@import_id int, @page_no int, @records_per_page int, @total_records int output as 
begin
		declare @count_query nvarchar(max);
		declare @main_query nvarchar(max);
		declare @where_clause nvarchar(max);
	
		set @count_query = 'select @total_records = COUNT(1) FROM Call_Result_Table_'+ cast(@campaignId as varchar) +' CR ';
		set @where_clause = ' WHERE CR.ImportList_Id = '+cast(@import_id as varchar)+' ';
		set @where_clause = @where_clause; 
		set @count_query = @count_query + @where_clause;
		execute sp_executesql @count_query, N'@total_records int output',@total_records output;
		set @main_query = 'WITH All_WrapupData AS(SELECT ROW_NUMBER() OVER(ORDER BY CR.ImportList_Id DESC) AS RowNumber ,CR.* FROM Call_Result_Table_'+ cast(@campaignId as varchar) +' CR ' + @where_clause + ') SELECT *  FROM All_WrapupData WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+')';
		exec(@main_query);
end











GO
/****** Object:  StoredProcedure [dbo].[Sp_Outbound_Agent_State_RT]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Outbound_Agent_State_RT]
@page_no int, @records_per_page int, @sort_by nvarchar(50) = 'DateTime' ,@direction nvarchar(4)='DESC', @total_records int output
as
begin 
declare @query nvarchar(max);
declare @queryCount nvarchar(max);
declare @count int;
Set @query='WITH AgentState AS( SELECT ROW_NUMBER() OVER(ORDER BY DateTime '+@direction+') AS RowNumber ,* from  OPENQUERY([192.168.1.34] ,''Select A.* ,ART.DateTime, 
	Case isnull(ART.AgentState,0) when 0 then ''''Logged Off''''
	 when 1 then ''''Logged On'''' when 2 then ''''Not Ready'''' when 3 then ''''Ready'''' when 4 then ''''Talking'''' when 5 then ''''Work Not Ready''''
	 when 6 then ''''Work Ready'''' when 7 then ''''Busy Other'''' else ''''Unknown'''' end as AgentState from
	(select C.CampaignID , CampaignName , CSG.SkillTargetID , SG.EnterpriseName as SkillGroupName , SGM.AgentSkillTargetID , 
	A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName    
	 from [ins11_awdb].[dbo].Campaign C inner join [ins11_awdb].[dbo].Campaign_Skill_Group CSG on (C.CampaignID = CSG.CampaignID)
	 inner join [ins11_awdb].[dbo].Skill_Group SG on (CSG.SkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Skill_Group_Member SGM on (SGM.SkillGroupSkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Agent A on (SGM.AgentSkillTargetID = A.SkillTargetID)
	 ) A Left Join [ins11_awdb].[dbo].Agent_Real_Time ART on (A.AgentSkillTargetID = ART.SkillTargetID)''))
	 
	 SELECT * FROM AgentState WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+' ';

	 Set @queryCount= 'SELECT @total_records = Count(*)  from  OPENQUERY([192.168.1.34] ,''Select A.* , ART.DateTime,
	Case isnull(ART.AgentState,0) when 0 then ''''Logged Off''''
	 when 1 then ''''Logged On'''' when 2 then ''''Not Ready'''' when 3 then ''''Ready'''' when 4 then ''''Talking'''' when 5 then ''''Work Not Ready''''
	 when 6 then ''''Work Ready'''' when 7 then ''''Busy Other'''' else ''''Unknown'''' end as AgentState from
	(select C.CampaignID , CampaignName , CSG.SkillTargetID , SG.EnterpriseName as SkillGroupName , SGM.AgentSkillTargetID , 
	A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName    
	 from [ins11_awdb].[dbo].Campaign C inner join [ins11_awdb].[dbo].Campaign_Skill_Group CSG on (C.CampaignID = CSG.CampaignID)
	 inner join [ins11_awdb].[dbo].Skill_Group SG on (CSG.SkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Skill_Group_Member SGM on (SGM.SkillGroupSkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Agent A on (SGM.AgentSkillTargetID = A.SkillTargetID)
	 ) A Left Join [ins11_awdb].[dbo].Agent_Real_Time ART on (A.AgentSkillTargetID = ART.SkillTargetID)'')';

	 exec(@query);
  
	
	 exec sp_executesql @queryCount , N'@total_records int output',@total_records output  ;




end






GO
/****** Object:  StoredProcedure [dbo].[Sp_Outbound_Agent_State_RT_Test]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Outbound_Agent_State_RT_Test]
@page_no int, @records_per_page int, @sort_by nvarchar(50) = 'DateTime' ,@direction nvarchar(4)='DESC', @total_records int output
as
begin 
declare @query nvarchar(max);
declare @queryCount nvarchar(max);
declare @count int;
Set @query='WITH AgentState AS( SELECT ROW_NUMBER() OVER(ORDER BY DateTime '+@direction+') AS RowNumber ,* from  OPENQUERY([192.168.1.34] ,''Select A.* ,ART.DateTime, 
	Case isnull(ART.AgentState,0) when 0 then ''''Logged Off''''
	 when 1 then ''''Logged On'''' when 2 then ''''Not Ready'''' when 3 then ''''Ready'''' when 4 then ''''Talking'''' when 5 then ''''Work Not Ready''''
	 when 6 then ''''Work Ready'''' when 7 then ''''Busy Other'''' else ''''Unknown'''' end as AgentState from
	(select C.CampaignID , CampaignName , CSG.SkillTargetID , SG.EnterpriseName as SkillGroupName , SGM.AgentSkillTargetID , 
	A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName    
	 from [ins11_awdb].[dbo].Campaign C inner join [ins11_awdb].[dbo].Campaign_Skill_Group CSG on (C.CampaignID = CSG.CampaignID)
	 inner join [ins11_awdb].[dbo].Skill_Group SG on (CSG.SkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Skill_Group_Member SGM on (SGM.SkillGroupSkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Agent A on (SGM.AgentSkillTargetID = A.SkillTargetID)
	 ) A Left Join [ins11_awdb].[dbo].Agent_Real_Time ART on (A.AgentSkillTargetID = ART.SkillTargetID)''))
	 
	 SELECT * FROM AgentState WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+' ';

	 Set @queryCount= 'SELECT @total_records = Count(*)  from  OPENQUERY([192.168.1.34] ,''Select A.* , ART.DateTime,
	Case isnull(ART.AgentState,0) when 0 then ''''Logged Off''''
	 when 1 then ''''Logged On'''' when 2 then ''''Not Ready'''' when 3 then ''''Ready'''' when 4 then ''''Talking'''' when 5 then ''''Work Not Ready''''
	 when 6 then ''''Work Ready'''' when 7 then ''''Busy Other'''' else ''''Unknown'''' end as AgentState from
	(select C.CampaignID , CampaignName , CSG.SkillTargetID , SG.EnterpriseName as SkillGroupName , SGM.AgentSkillTargetID , 
	A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName    
	 from [ins11_awdb].[dbo].Campaign C inner join [ins11_awdb].[dbo].Campaign_Skill_Group CSG on (C.CampaignID = CSG.CampaignID)
	 inner join [ins11_awdb].[dbo].Skill_Group SG on (CSG.SkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Skill_Group_Member SGM on (SGM.SkillGroupSkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Agent A on (SGM.AgentSkillTargetID = A.SkillTargetID)
	 ) A Left Join [ins11_awdb].[dbo].Agent_Real_Time ART on (A.AgentSkillTargetID = ART.SkillTargetID)'')';

	 exec(@query);
  
	
	 exec sp_executesql @queryCount , N'@total_records int output',@total_records output  ;




end






GO
/****** Object:  StoredProcedure [dbo].[Sp_Outbound_Agent_State_RT_Test_1]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Outbound_Agent_State_RT_Test_1]
@page_no int, @records_per_page int, @sort_by nvarchar(50) = 'CampaignID' ,@direction nvarchar(4)='DESC', @total_records int output
as
begin 
declare @query nvarchar(max);
declare @queryCount nvarchar(max);
declare @count int;
Set @query='WITH AgentState AS( SELECT ROW_NUMBER() OVER(ORDER BY CampaignID '+@direction+') AS RowNumber ,* from  OPENQUERY([192.168.1.34] ,''Select A.* , 
	Case isnull(ART.AgentState,0) when 0 then ''''Logged Off''''
	 when 1 then ''''Logged On'''' when 2 then ''''Not Ready'''' when 3 then ''''Ready'''' when 4 then ''''Talking'''' when 5 then ''''Work Not Ready''''
	 when 6 then ''''Work Ready'''' when 7 then ''''Busy Other'''' else ''''Unknown'''' end as AgentState from
	(select C.CampaignID , CampaignName , CSG.SkillTargetID , SG.EnterpriseName as SkillGroupName , SGM.AgentSkillTargetID , 
	A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName    
	 from [ins11_awdb].[dbo].Campaign C inner join [ins11_awdb].[dbo].Campaign_Skill_Group CSG on (C.CampaignID = CSG.CampaignID)
	 inner join [ins11_awdb].[dbo].Skill_Group SG on (CSG.SkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Skill_Group_Member SGM on (SGM.SkillGroupSkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Agent A on (SGM.AgentSkillTargetID = A.SkillTargetID)
	 ) A Left Join [ins11_awdb].[dbo].Agent_Real_Time ART on (A.AgentSkillTargetID = ART.SkillTargetID)''))
	 
	 SELECT * FROM AgentState WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+'
	
	
	 ';
	 Set @queryCount=  'SELECT @total_records =  Count(*)  from  OPENQUERY([192.168.1.34] ,''Select A.* , 
	Case isnull(ART.AgentState,0) when 0 then ''''Logged Off''''
	 when 1 then ''''Logged On'''' when 2 then ''''Not Ready'''' when 3 then ''''Ready'''' when 4 then ''''Talking'''' when 5 then ''''Work Not Ready''''
	 when 6 then ''''Work Ready'''' when 7 then ''''Busy Other'''' else ''''Unknown'''' end as AgentState from
	(select C.CampaignID , CampaignName , CSG.SkillTargetID , SG.EnterpriseName as SkillGroupName , SGM.AgentSkillTargetID , 
	A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName    
	 from [ins11_awdb].[dbo].Campaign C inner join [ins11_awdb].[dbo].Campaign_Skill_Group CSG on (C.CampaignID = CSG.CampaignID)
	 inner join [ins11_awdb].[dbo].Skill_Group SG on (CSG.SkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Skill_Group_Member SGM on (SGM.SkillGroupSkillTargetID = SG.SkillTargetID)
	 inner join [ins11_awdb].[dbo].Agent A on (SGM.AgentSkillTargetID = A.SkillTargetID)
	 ) A Left Join [ins11_awdb].[dbo].Agent_Real_Time ART on (A.AgentSkillTargetID = ART.SkillTargetID)'')';

	 exec(@query);
     exec sp_executesql @queryCount , N'@total_records int output',@total_records output  ;
	 --set @total_records = @total_records;
	
	
	
	
end






GO
/****** Object:  StoredProcedure [dbo].[Sp_Outbound_Call_Detail]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Outbound_Call_Detail]
@StartDate as Date,
@EndDate as Date,
@CallResult as Int,
@page_no int,
@records_per_page int,
@sort_by nvarchar(50) = 'DateTime' ,
@direction nvarchar(4)='DESC',
@total_records int output
as begin 
declare @query as nvarchar(max);
declare @queryWhere as nvarchar(max);
declare @mainQuery as nvarchar(max);
declare @queryCount as nvarchar(max);
declare @queryCountWhere as nvarchar(max);
declare @mainQueryCount as nvarchar(max);
set @query=
'
WITH cte AS( SELECT ROW_NUMBER() OVER(ORDER BY DateTime '+@direction+') AS RowNumber , * from  OPENQUERY([192.168.1.34] ,''
SELECT TOP 7000
DialerName = Dialer.DialerName,
DateTime = DialerD.DateTime,
CampaignName = Campaign.CampaignName,
TimeZone = DialerD.TimeZone,
SkillGroupName = Skill_Group.EnterpriseName,
CustomerName = DialerD.LastName + '''', '''' + DialerD.FirstName,
PhoneDialed = DialerD.Phone,
CustomerCallbackPhone = DialerD.CallbackPhone,
CallbackDateTime = DialerD.CallbackDateTime,
WrapupName = DialerD.WrapupData,
ReservationCallDuration = isnull(DialerD.ReservationCallDuration,0)/1000,
PreviewTime = isnull(DialerD.PreviewTime,0),
DialerCallDuration = isnull(DialerD.CallDuration,0)/1000,
TCDCallDuration = isnull(TCD.Duration,0),
MRDName = Media_Routing_Domain.EnterpriseName,
AgentName = Person.LastName + '''', '''' + Person.FirstName,
NetworkTime = isnull(TCD.NetworkTime,0),
RingTime = isnull(TCD.RingTime,0),
DelayTime = isnull(TCD.DelayTime,0),
TimeToAband = isnull(TCD.TimeToAband,0),
HoldTime = isnull(TCD.HoldTime,0),
TalkTime = isnull(TCD.TalkTime,0),
WorkTime = isnull(TCD.WorkTime,0),
AnsweredWithinServiceLevel = TCD.AnsweredWithinServiceLevel,
CallReferenceID = TCD.CallReferenceID,
CallDisposition = TCD.CallDisposition,
CallDispositionFlag = TCD.CallDispositionFlag,
CallResult = DialerD.CallResult,
CallResultDetail = DialerD.CallResultDetail,
PeripheralCallKey = TCD.PeripheralCallKey,
SIPResponseCode = DialerD.CallGUID,
CallResultName = CASE DialerD.CallResult WHEN 2 THEN ''''Error condition while dialing''''
WHEN 3 THEN ''''Number reported not in service by network''''
WHEN 4 THEN ''''No ringback from network when dial attempted''''
WHEN 5 THEN ''''Operator intercept returned from network when dial attempted''''
WHEN 6 THEN ''''No dial tone when dialer port went off hook''''
WHEN 7 THEN ''''Number reported as invalid by the network''''
WHEN 8 THEN ''''Customer phone did not answer''''
WHEN 9 THEN ''''Customer phone was busy''''
WHEN 10 THEN ''''Customer answered and was connected to agent''''
WHEN 11 THEN ''''Fax machine detected''''
WHEN 12 THEN ''''Answering machine detected''''
WHEN 13 THEN ''''Dialer stopped dialing customer due to lack of agents or network stopped dialing before it was complete''''
WHEN 14 THEN ''''Customer requested callback''''
WHEN 16 THEN ''''Call was abandoned by the dialer due to lack of agents''''
WHEN 17 THEN ''''Failed to reserve agent for personal callback''''
WHEN 18 THEN ''''Agent has skipped or rejected a preview call''''
WHEN 19 THEN ''''Agent has skipped or rejected a preview call with the close option''''
WHEN 20 THEN ''''Customer has been abandoned to an IVR''''
WHEN 21 THEN ''''Customer dropped call within configured abandoned time''''
WHEN 22 THEN ''''Mostly used with TDM switches - network answering machine, such as a network voicemail''''
WHEN 23 THEN ''''Number successfully contacted but wrong number''''
WHEN 24 THEN ''''Number successfully contacted but reached the wrong person''''
WHEN 25 THEN ''''Dialer has flushed this record due to a change in the skillgroup. the campaign, etc.''''
WHEN 26 THEN ''''The number was on the do not call list''''
WHEN 27 THEN ''''Call disconnected by the carrier or the network while ringing''''
WHEN 28 THEN ''''Dead air or low voice volume call''''
ELSE ''''Unknown Call Result'''' END



FROM (Select * from [ins11_awdb].[dbo].Dialer_Detail
WHERE DateTime >='''''+cast(@StartDate as nvarchar(50))+'''''
AND DateTime < '''''+cast(@EndDate as nvarchar(50))+'''''
AND CallResult IN ('''''+cast(@CallResult as nvarchar(50))+''''')
) 
DialerD
LEFT OUTER JOIN [ins11_awdb].[dbo].Dialer (nolock) ON DialerD.DialerID = Dialer.DialerID
LEFT OUTER JOIN [ins11_awdb].[dbo].Campaign (nolock) ON DialerD.CampaignID = Campaign.CampaignID
LEFT OUTER JOIN [ins11_awdb].[dbo].Skill_Group (nolock) ON DialerD.SkillGroupSkillTargetID = Skill_Group.SkillTargetID
LEFT OUTER JOIN (Select * from [ins11_hds].[dbo].Termination_Call_Detail (nolock)


'

set @queryWhere='WHERE DateTime >= '''''+cast(@StartDate as nvarchar(50))+'''''
AND DateTime < '''''+cast(@EndDate as nvarchar(50))+'''''
AND PeripheralCallType IN (32,33,34,35)
AND Originated = ''''D'''') TCD ON TCD.RouterCallKey = DialerD.RouterCallKey
AND TCD.RouterCallKeyDay = DialerD.RouterCallKeyDay
LEFT OUTER JOIN [ins11_awdb].[dbo].Media_Routing_Domain (nolock) ON TCD.MRDomainID = Media_Routing_Domain.MRDomainID
LEFT OUTER JOIN [ins11_awdb].[dbo].Agent (nolock) ON TCD.AgentSkillTargetID = Agent.SkillTargetID
LEFT OUTER JOIN [ins11_awdb].[dbo].Person (nolock) ON Agent.PersonID = Person.PersonID

ORDER BY DialerD.DateTime'')) 
SELECT * FROM cte WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+' ';


SET @mainQuery = @query + @queryWhere;



set @queryCount=
'
Select @total_records = Count(*) from  OPENQUERY([192.168.1.34] ,''SELECT TOP 7000
DialerName = Dialer.DialerName,
DateTime = DialerD.DateTime,
CampaignName = Campaign.CampaignName,
TimeZone = DialerD.TimeZone,
SkillGroupName = Skill_Group.EnterpriseName,
CustomerName = DialerD.LastName + '''', '''' + DialerD.FirstName,
PhoneDialed = DialerD.Phone,
CustomerCallbackPhone = DialerD.CallbackPhone,
CallbackDateTime = DialerD.CallbackDateTime,
WrapupName = DialerD.WrapupData,
ReservationCallDuration = isnull(DialerD.ReservationCallDuration,0)/1000,
PreviewTime = isnull(DialerD.PreviewTime,0),
DialerCallDuration = isnull(DialerD.CallDuration,0)/1000,
TCDCallDuration = isnull(TCD.Duration,0),
MRDName = Media_Routing_Domain.EnterpriseName,
AgentName = Person.LastName + '''', '''' + Person.FirstName,
NetworkTime = isnull(TCD.NetworkTime,0),
RingTime = isnull(TCD.RingTime,0),
DelayTime = isnull(TCD.DelayTime,0),
TimeToAband = isnull(TCD.TimeToAband,0),
HoldTime = isnull(TCD.HoldTime,0),
TalkTime = isnull(TCD.TalkTime,0),
WorkTime = isnull(TCD.WorkTime,0),
AnsweredWithinServiceLevel = TCD.AnsweredWithinServiceLevel,
CallReferenceID = TCD.CallReferenceID,
CallDisposition = TCD.CallDisposition,
CallDispositionFlag = TCD.CallDispositionFlag,
CallResult = DialerD.CallResult,
CallResultDetail = DialerD.CallResultDetail,
PeripheralCallKey = TCD.PeripheralCallKey,
SIPResponseCode = DialerD.CallGUID,
CallResultName = CASE DialerD.CallResult WHEN 2 THEN ''''Error condition while dialing''''
WHEN 3 THEN ''''Number reported not in service by network''''
WHEN 4 THEN ''''No ringback from network when dial attempted''''
WHEN 5 THEN ''''Operator intercept returned from network when dial attempted''''
WHEN 6 THEN ''''No dial tone when dialer port went off hook''''
WHEN 7 THEN ''''Number reported as invalid by the network''''
WHEN 8 THEN ''''Customer phone did not answer''''
WHEN 9 THEN ''''Customer phone was busy''''
WHEN 10 THEN ''''Customer answered and was connected to agent''''
WHEN 11 THEN ''''Fax machine detected''''
WHEN 12 THEN ''''Answering machine detected''''
WHEN 13 THEN ''''Dialer stopped dialing customer due to lack of agents or network stopped dialing before it was complete''''
WHEN 14 THEN ''''Customer requested callback''''
WHEN 16 THEN ''''Call was abandoned by the dialer due to lack of agents''''
WHEN 17 THEN ''''Failed to reserve agent for personal callback''''
WHEN 18 THEN ''''Agent has skipped or rejected a preview call''''
WHEN 19 THEN ''''Agent has skipped or rejected a preview call with the close option''''
WHEN 20 THEN ''''Customer has been abandoned to an IVR''''
WHEN 21 THEN ''''Customer dropped call within configured abandoned time''''
WHEN 22 THEN ''''Mostly used with TDM switches - network answering machine, such as a network voicemail''''
WHEN 23 THEN ''''Number successfully contacted but wrong number''''
WHEN 24 THEN ''''Number successfully contacted but reached the wrong person''''
WHEN 25 THEN ''''Dialer has flushed this record due to a change in the skillgroup. the campaign, etc.''''
WHEN 26 THEN ''''The number was on the do not call list''''
WHEN 27 THEN ''''Call disconnected by the carrier or the network while ringing''''
WHEN 28 THEN ''''Dead air or low voice volume call''''
ELSE ''''Unknown Call Result'''' END



FROM (Select * from [ins11_hds].[dbo].Dialer_Detail
WHERE DateTime >='''''+cast(@StartDate as nvarchar(50))+'''''
AND DateTime < '''''+cast(@EndDate as nvarchar(50))+'''''
AND CallResult IN ('''''+cast(@CallResult as nvarchar(50))+''''')
) 
DialerD
LEFT OUTER JOIN [ins11_hds].[dbo].Dialer (nolock) ON DialerD.DialerID = Dialer.DialerID
LEFT OUTER JOIN [ins11_hds].[dbo].Campaign (nolock) ON DialerD.CampaignID = Campaign.CampaignID
LEFT OUTER JOIN [ins11_hds].[dbo].Skill_Group (nolock) ON DialerD.SkillGroupSkillTargetID = Skill_Group.SkillTargetID
LEFT OUTER JOIN (Select * from [ins11_hds].[dbo].Termination_Call_Detail (nolock)
'

set @queryCountWhere='WHERE DateTime >= '''''+cast(@StartDate as nvarchar(50))+'''''
AND DateTime < '''''+cast(@EndDate as nvarchar(50))+'''''
AND PeripheralCallType IN (32,33,34,35)
AND Originated = ''''D'''') TCD ON TCD.RouterCallKey = DialerD.RouterCallKey
AND TCD.RouterCallKeyDay = DialerD.RouterCallKeyDay
LEFT OUTER JOIN [ins11_hds].[dbo].Media_Routing_Domain (nolock) ON TCD.MRDomainID = Media_Routing_Domain.MRDomainID
LEFT OUTER JOIN [ins11_hds].[dbo].Agent (nolock) ON TCD.AgentSkillTargetID = Agent.SkillTargetID
LEFT OUTER JOIN [ins11_hds].[dbo].Person (nolock) ON Agent.PersonID = Person.PersonID

ORDER BY DialerD.DateTime'' )
';

SET @mainQueryCount = @queryCount + @queryCountWhere;
exec(@mainQuery)
exec sp_executesql @mainQueryCount , N'@total_records int output',@total_records output  ;
End






GO
/****** Object:  StoredProcedure [dbo].[Sp_Outbound_Call_Detail_Interval]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Sp_Outbound_Call_Detail_Interval]
@StartDate Datetime,
@EndDate Datetime,
@page_no int,
@records_per_page int,
@sort_by nvarchar(50) = 'DateTime' ,
@direction nvarchar(4)='DESC',
@total_records int output
as Begin
Declare @dynamicSql nvarchar(max);
Declare @queryCount nvarchar(max);
set @dynamicSql= 
				'WITH cte AS( SELECT ROW_NUMBER() OVER(ORDER BY DateTime '+@direction+') AS RowNumber ,* from  OPENQUERY([192.168.1.34] ,''
  select DateTime,A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName , AgentOutCalls ,
 TalkOutTime as Talktime , PreviewCalls , PreviewCallsTime , PreviewCallsTalkTime , PreviewCallsOnHold , PreviewCallsOnHoldTime from
  [ins11_awdb].[dbo].Agent_Skill_Group_Interval ASG inner join [ins11_awdb].[dbo].Agent A on (ASG.SkillTargetID = A.SkillTargetID)
 Where ASG.DateTime between'''''+cast(@StartDate as nvarchar(50))+''''' and '''''+cast(@EndDate as nvarchar(50))+'''''
 ''))
 
 SELECT * FROM cte WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+' ';


set @queryCount= 
				'Select @total_records = Count(*) from  OPENQUERY([192.168.1.34] ,''
  select DateTime,A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName , AgentOutCalls ,
 TalkOutTime as Talktime , PreviewCalls , PreviewCallsTime , PreviewCallsTalkTime , PreviewCallsOnHold , PreviewCallsOnHoldTime from
  [ins11_awdb].[dbo].Agent_Skill_Group_Interval ASG inner join [ins11_awdb].[dbo].Agent A on (ASG.SkillTargetID = A.SkillTargetID)
 Where ASG.DateTime between'''''+cast(@StartDate as nvarchar(50))+''''' and '''''+cast(@EndDate as nvarchar(50))+'''''
 '')';

 exec(@dynamicSql);
 exec sp_executesql @queryCount , N'@total_records int output',@total_records output  ;
 End






GO
/****** Object:  StoredProcedure [dbo].[Sp_Outbound_Call_Detail_sa]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Outbound_Call_Detail_sa]
@StartDate as Date,
@EndDate as Date,
@CallResult as Int
as begin 
declare @dynamicSql nvarchar(MAX);
				set @dynamicSql = '
					Select * from  OPENQUERY([192.168.1.34] ,''
SELECT TOP 7000
DialerName = Dialer.DialerName,
DateTime = DialerD.DateTime,
CampaignName = Campaign.CampaignName,
TimeZone = DialerD.TimeZone,
SkillGroupName = Skill_Group.EnterpriseName,
CustomerName = DialerD.LastName + '', '' + DialerD.FirstName,
PhoneDialed = DialerD.Phone,
CustomerCallbackPhone = DialerD.CallbackPhone,
CallbackDateTime = DialerD.CallbackDateTime,
WrapupName = DialerD.WrapupData,
ReservationCallDuration = isnull(DialerD.ReservationCallDuration,0)/1000,
PreviewTime = isnull(DialerD.PreviewTime,0),
DialerCallDuration = isnull(DialerD.CallDuration,0)/1000,
TCDCallDuration = isnull(TCD.Duration,0),
MRDName = Media_Routing_Domain.EnterpriseName,
AgentName = Person.LastName + '', '' + Person.FirstName,
NetworkTime = isnull(TCD.NetworkTime,0),
RingTime = isnull(TCD.RingTime,0),
DelayTime = isnull(TCD.DelayTime,0),
TimeToAband = isnull(TCD.TimeToAband,0),
HoldTime = isnull(TCD.HoldTime,0),
TalkTime = isnull(TCD.TalkTime,0),
WorkTime = isnull(TCD.WorkTime,0),
AnsweredWithinServiceLevel = TCD.AnsweredWithinServiceLevel,
CallReferenceID = TCD.CallReferenceID,
CallDisposition = TCD.CallDisposition,
CallDispositionFlag = TCD.CallDispositionFlag,
CallResult = DialerD.CallResult,
CallResultDetail = DialerD.CallResultDetail,
PeripheralCallKey = TCD.PeripheralCallKey,
SIPResponseCode = DialerD.CallGUID,
CallResultName = CASE DialerD.CallResult WHEN 2 THEN ''Error condition while dialing''
WHEN 3 THEN ''Number reported not in service by network''
WHEN 4 THEN ''No ringback from network when dial attempted''
WHEN 5 THEN ''Operator intercept returned from network when dial attempted''
WHEN 6 THEN ''No dial tone when dialer port went off hook''
WHEN 7 THEN ''Number reported as invalid by the network''
WHEN 8 THEN ''Customer phone did not answer''
WHEN 9 THEN ''Customer phone was busy''
WHEN 10 THEN ''Customer answered and was connected to agent''
WHEN 11 THEN ''Fax machine detected''
WHEN 12 THEN ''Answering machine detected''
WHEN 13 THEN ''Dialer stopped dialing customer due to lack of agents or network stopped dialing before it was complete''
WHEN 14 THEN ''Customer requested callback''
WHEN 16 THEN ''Call was abandoned by the dialer due to lack of agents''
WHEN 17 THEN ''Failed to reserve agent for personal callback''
WHEN 18 THEN ''Agent has skipped or rejected a preview call''
WHEN 19 THEN ''Agent has skipped or rejected a preview call with the close option''
WHEN 20 THEN ''Customer has been abandoned to an IVR''
WHEN 21 THEN ''Customer dropped call within configured abandoned time''
WHEN 22 THEN ''Mostly used with TDM switches - network answering machine, such as a network voicemail''
WHEN 23 THEN ''Number successfully contacted but wrong number''
WHEN 24 THEN ''Number successfully contacted but reached the wrong person''
WHEN 25 THEN ''Dialer has flushed this record due to a change in the skillgroup. the campaign, etc.''
WHEN 26 THEN ''The number was on the do not call list''
WHEN 27 THEN ''Call disconnected by the carrier or the network while ringing''
WHEN 28 THEN ''Dead air or low voice volume call''
ELSE ''Unknown Call Result'' END
FROM (Select * from [ins11_hds].[dbo].Dialer_Detail
WHERE DateTime >= ''+cast(@StartDate as nvarchar(50))+''
AND DateTime <''+cast(@EndDate as nvarchar(50))+''
AND CallResult IN (''+cast(@CallResult as nvarchar(50))+'')
)
DialerD
LEFT OUTER JOIN [ins11_hd].[dbo].Dialer (nolock) ON DialerD.DialerID = Dialer.DialerID
LEFT OUTER JOIN [ins11_hds].[dbo].Campaign (nolock) ON DialerD.CampaignID = Campaign.CampaignID
LEFT OUTER JOIN [ins11_hds].[dbo].Skill_Group (nolock) ON DialerD.SkillGroupSkillTargetID = Skill_Group.SkillTargetID
LEFT OUTER JOIN (Select * from [ins11_hds].[dbo].Termination_Call_Detail (nolock)
WHERE DateTime >= ''+cast(@StartDate as nvarchar(50))+''
AND DateTime < ''+cast(@EndDate as nvarchar(50))+''
AND PeripheralCallType IN (32,33,34,35)
AND Originated = ''''D'''') TCD ON TCD.RouterCallKey = DialerD.RouterCallKey
AND TCD.RouterCallKeyDay = DialerD.RouterCallKeyDay
LEFT OUTER JOIN [ins11_hds].[dbo]Media_Routing_Domain (nolock) ON TCD.MRDomainID = Media_Routing_Domain.MRDomainID
LEFT OUTER JOIN [ins11_hds].[dbo]Agent (nolock) ON TCD.AgentSkillTargetID = Agent.SkillTargetID
LEFT OUTER JOIN [ins11_hds].[dbo]Person (nolock) ON Agent.PersonID = Person.PersonID
ORDER BY DialerD.DateTime

''
)';

select (@dynamicSql);
--print(@dynamicSql);
exec(@dynamicSql);
End






GO
/****** Object:  StoredProcedure [dbo].[Sp_Outbound_Call_Detail_Test]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Outbound_Call_Detail_Test]
@StartDate as Date,
@EndDate as Date,
@CallResult as Int,
@page_no int,
@records_per_page int,
@sort_by nvarchar(50) = 'DateTime' ,
@direction nvarchar(4)='DESC',
@total_records int output
as begin 
declare @query as nvarchar(max);
declare @queryWhere as nvarchar(max);
declare @mainQuery as nvarchar(max);
declare @queryCount as nvarchar(max);
declare @queryCountWhere as nvarchar(max);
declare @mainQueryCount as nvarchar(max);
set @query=
'
WITH cte AS( SELECT ROW_NUMBER() OVER(ORDER BY DateTime '+@direction+') AS RowNumber , * from  OPENQUERY([192.168.1.34] ,''SELECT TOP 7000
DialerName = Dialer.DialerName,
DateTime = DialerD.DateTime,
CampaignName = Campaign.CampaignName,
TimeZone = DialerD.TimeZone,
SkillGroupName = Skill_Group.EnterpriseName,
CustomerName = DialerD.LastName + '''', '''' + DialerD.FirstName,
PhoneDialed = DialerD.Phone,
CustomerCallbackPhone = DialerD.CallbackPhone,
CallbackDateTime = DialerD.CallbackDateTime,
WrapupName = DialerD.WrapupData,
ReservationCallDuration = isnull(DialerD.ReservationCallDuration,0)/1000,
PreviewTime = isnull(DialerD.PreviewTime,0),
DialerCallDuration = isnull(DialerD.CallDuration,0)/1000,
TCDCallDuration = isnull(TCD.Duration,0),
MRDName = Media_Routing_Domain.EnterpriseName,
AgentName = Person.LastName + '''', '''' + Person.FirstName,
NetworkTime = isnull(TCD.NetworkTime,0),
RingTime = isnull(TCD.RingTime,0),
DelayTime = isnull(TCD.DelayTime,0),
TimeToAband = isnull(TCD.TimeToAband,0),
HoldTime = isnull(TCD.HoldTime,0),
TalkTime = isnull(TCD.TalkTime,0),
WorkTime = isnull(TCD.WorkTime,0),
AnsweredWithinServiceLevel = TCD.AnsweredWithinServiceLevel,
CallReferenceID = TCD.CallReferenceID,
CallDisposition = TCD.CallDisposition,
CallDispositionFlag = TCD.CallDispositionFlag,
CallResult = DialerD.CallResult,
CallResultDetail = DialerD.CallResultDetail,
PeripheralCallKey = TCD.PeripheralCallKey,
SIPResponseCode = DialerD.CallGUID,
CallResultName = CASE DialerD.CallResult WHEN 2 THEN ''''Error condition while dialing''''
WHEN 3 THEN ''''Number reported not in service by network''''
WHEN 4 THEN ''''No ringback from network when dial attempted''''
WHEN 5 THEN ''''Operator intercept returned from network when dial attempted''''
WHEN 6 THEN ''''No dial tone when dialer port went off hook''''
WHEN 7 THEN ''''Number reported as invalid by the network''''
WHEN 8 THEN ''''Customer phone did not answer''''
WHEN 9 THEN ''''Customer phone was busy''''
WHEN 10 THEN ''''Customer answered and was connected to agent''''
WHEN 11 THEN ''''Fax machine detected''''
WHEN 12 THEN ''''Answering machine detected''''
WHEN 13 THEN ''''Dialer stopped dialing customer due to lack of agents or network stopped dialing before it was complete''''
WHEN 14 THEN ''''Customer requested callback''''
WHEN 16 THEN ''''Call was abandoned by the dialer due to lack of agents''''
WHEN 17 THEN ''''Failed to reserve agent for personal callback''''
WHEN 18 THEN ''''Agent has skipped or rejected a preview call''''
WHEN 19 THEN ''''Agent has skipped or rejected a preview call with the close option''''
WHEN 20 THEN ''''Customer has been abandoned to an IVR''''
WHEN 21 THEN ''''Customer dropped call within configured abandoned time''''
WHEN 22 THEN ''''Mostly used with TDM switches - network answering machine, such as a network voicemail''''
WHEN 23 THEN ''''Number successfully contacted but wrong number''''
WHEN 24 THEN ''''Number successfully contacted but reached the wrong person''''
WHEN 25 THEN ''''Dialer has flushed this record due to a change in the skillgroup. the campaign, etc.''''
WHEN 26 THEN ''''The number was on the do not call list''''
WHEN 27 THEN ''''Call disconnected by the carrier or the network while ringing''''
WHEN 28 THEN ''''Dead air or low voice volume call''''
ELSE ''''Unknown Call Result'''' END



FROM (Select * from [ins11_hds].[dbo].Dialer_Detail
WHERE DateTime >='''''+cast(@StartDate as nvarchar(50))+'''''
AND DateTime < '''''+cast(@EndDate as nvarchar(50))+'''''
AND CallResult IN ('''''+cast(@CallResult as nvarchar(50))+''''')
) 
DialerD
LEFT OUTER JOIN [ins11_hds].[dbo].Dialer (nolock) ON DialerD.DialerID = Dialer.DialerID
LEFT OUTER JOIN [ins11_hds].[dbo].Campaign (nolock) ON DialerD.CampaignID = Campaign.CampaignID
LEFT OUTER JOIN [ins11_hds].[dbo].Skill_Group (nolock) ON DialerD.SkillGroupSkillTargetID = Skill_Group.SkillTargetID
LEFT OUTER JOIN (Select * from [ins11_hds].[dbo].Termination_Call_Detail (nolock)


'

set @queryWhere='WHERE DateTime >= '''''+cast(@StartDate as nvarchar(50))+'''''
AND DateTime < '''''+cast(@EndDate as nvarchar(50))+'''''
AND PeripheralCallType IN (32,33,34,35)
AND Originated = ''''D'''') TCD ON TCD.RouterCallKey = DialerD.RouterCallKey
AND TCD.RouterCallKeyDay = DialerD.RouterCallKeyDay
LEFT OUTER JOIN [ins11_hds].[dbo].Media_Routing_Domain (nolock) ON TCD.MRDomainID = Media_Routing_Domain.MRDomainID
LEFT OUTER JOIN [ins11_hds].[dbo].Agent (nolock) ON TCD.AgentSkillTargetID = Agent.SkillTargetID
LEFT OUTER JOIN [ins11_hds].[dbo].Person (nolock) ON Agent.PersonID = Person.PersonID

ORDER BY DialerD.DateTime'')) 
SELECT * FROM cte WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+' ';


SET @mainQuery = @query + @queryWhere;



set @queryCount=
'
Select @total_records = Count(*) from  OPENQUERY([192.168.1.34] ,''SELECT TOP 7000
DialerName = Dialer.DialerName,
DateTime = DialerD.DateTime,
CampaignName = Campaign.CampaignName,
TimeZone = DialerD.TimeZone,
SkillGroupName = Skill_Group.EnterpriseName,
CustomerName = DialerD.LastName + '''', '''' + DialerD.FirstName,
PhoneDialed = DialerD.Phone,
CustomerCallbackPhone = DialerD.CallbackPhone,
CallbackDateTime = DialerD.CallbackDateTime,
WrapupName = DialerD.WrapupData,
ReservationCallDuration = isnull(DialerD.ReservationCallDuration,0)/1000,
PreviewTime = isnull(DialerD.PreviewTime,0),
DialerCallDuration = isnull(DialerD.CallDuration,0)/1000,
TCDCallDuration = isnull(TCD.Duration,0),
MRDName = Media_Routing_Domain.EnterpriseName,
AgentName = Person.LastName + '''', '''' + Person.FirstName,
NetworkTime = isnull(TCD.NetworkTime,0),
RingTime = isnull(TCD.RingTime,0),
DelayTime = isnull(TCD.DelayTime,0),
TimeToAband = isnull(TCD.TimeToAband,0),
HoldTime = isnull(TCD.HoldTime,0),
TalkTime = isnull(TCD.TalkTime,0),
WorkTime = isnull(TCD.WorkTime,0),
AnsweredWithinServiceLevel = TCD.AnsweredWithinServiceLevel,
CallReferenceID = TCD.CallReferenceID,
CallDisposition = TCD.CallDisposition,
CallDispositionFlag = TCD.CallDispositionFlag,
CallResult = DialerD.CallResult,
CallResultDetail = DialerD.CallResultDetail,
PeripheralCallKey = TCD.PeripheralCallKey,
SIPResponseCode = DialerD.CallGUID,
CallResultName = CASE DialerD.CallResult WHEN 2 THEN ''''Error condition while dialing''''
WHEN 3 THEN ''''Number reported not in service by network''''
WHEN 4 THEN ''''No ringback from network when dial attempted''''
WHEN 5 THEN ''''Operator intercept returned from network when dial attempted''''
WHEN 6 THEN ''''No dial tone when dialer port went off hook''''
WHEN 7 THEN ''''Number reported as invalid by the network''''
WHEN 8 THEN ''''Customer phone did not answer''''
WHEN 9 THEN ''''Customer phone was busy''''
WHEN 10 THEN ''''Customer answered and was connected to agent''''
WHEN 11 THEN ''''Fax machine detected''''
WHEN 12 THEN ''''Answering machine detected''''
WHEN 13 THEN ''''Dialer stopped dialing customer due to lack of agents or network stopped dialing before it was complete''''
WHEN 14 THEN ''''Customer requested callback''''
WHEN 16 THEN ''''Call was abandoned by the dialer due to lack of agents''''
WHEN 17 THEN ''''Failed to reserve agent for personal callback''''
WHEN 18 THEN ''''Agent has skipped or rejected a preview call''''
WHEN 19 THEN ''''Agent has skipped or rejected a preview call with the close option''''
WHEN 20 THEN ''''Customer has been abandoned to an IVR''''
WHEN 21 THEN ''''Customer dropped call within configured abandoned time''''
WHEN 22 THEN ''''Mostly used with TDM switches - network answering machine, such as a network voicemail''''
WHEN 23 THEN ''''Number successfully contacted but wrong number''''
WHEN 24 THEN ''''Number successfully contacted but reached the wrong person''''
WHEN 25 THEN ''''Dialer has flushed this record due to a change in the skillgroup. the campaign, etc.''''
WHEN 26 THEN ''''The number was on the do not call list''''
WHEN 27 THEN ''''Call disconnected by the carrier or the network while ringing''''
WHEN 28 THEN ''''Dead air or low voice volume call''''
ELSE ''''Unknown Call Result'''' END



FROM (Select * from [ins11_hds].[dbo].Dialer_Detail
WHERE DateTime >='''''+cast(@StartDate as nvarchar(50))+'''''
AND DateTime < '''''+cast(@EndDate as nvarchar(50))+'''''
AND CallResult IN ('''''+cast(@CallResult as nvarchar(50))+''''')
) 
DialerD
LEFT OUTER JOIN [ins11_hds].[dbo].Dialer (nolock) ON DialerD.DialerID = Dialer.DialerID
LEFT OUTER JOIN [ins11_hds].[dbo].Campaign (nolock) ON DialerD.CampaignID = Campaign.CampaignID
LEFT OUTER JOIN [ins11_hds].[dbo].Skill_Group (nolock) ON DialerD.SkillGroupSkillTargetID = Skill_Group.SkillTargetID
LEFT OUTER JOIN (Select * from [ins11_hds].[dbo].Termination_Call_Detail (nolock)
'

set @queryCountWhere='WHERE DateTime >= '''''+cast(@StartDate as nvarchar(50))+'''''
AND DateTime < '''''+cast(@EndDate as nvarchar(50))+'''''
AND PeripheralCallType IN (32,33,34,35)
AND Originated = ''''D'''') TCD ON TCD.RouterCallKey = DialerD.RouterCallKey
AND TCD.RouterCallKeyDay = DialerD.RouterCallKeyDay
LEFT OUTER JOIN [ins11_hds].[dbo].Media_Routing_Domain (nolock) ON TCD.MRDomainID = Media_Routing_Domain.MRDomainID
LEFT OUTER JOIN [ins11_hds].[dbo].Agent (nolock) ON TCD.AgentSkillTargetID = Agent.SkillTargetID
LEFT OUTER JOIN [ins11_hds].[dbo].Person (nolock) ON Agent.PersonID = Person.PersonID

ORDER BY DialerD.DateTime'' )
';

SET @mainQueryCount = @queryCount + @queryCountWhere;
exec(@mainQuery)
exec sp_executesql @mainQueryCount , N'@total_records int output',@total_records output  ;
End






GO
/****** Object:  StoredProcedure [dbo].[SP_PreviewCampaignSkills]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE Procedure [dbo].[SP_PreviewCampaignSkills]  
	@dealer_id int,
	@campaign_id nvarchar(255), 
	@skill_targetId int

	as begin
	declare @table Table (SkillMapId int)
	insert into SkillGroupMap 
	(
		PreviewCampaignId, SkillTargetID,DealerId
	) output inserted.PreviewCampaignId into @table
	values 
	(
		@campaign_id, @skill_targetId,@dealer_id
	)
	Select * from @table;
end








GO
/****** Object:  StoredProcedure [dbo].[SP_Rechurn]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Rechurn] 
	@campaign_id int , 
	@map_id_string nvarchar(max),
	@call_result_string nvarchar(max) = null,
	@wrapup_string nvarchar(max) = null,
	@attempt_string nvarchar(max) = null

as begin
	SET NOCOUNT ON; 
	declare @insert_sql nvarchar(max);
	declare @insert_sql1 nvarchar(max);
	set @insert_sql='';
	set @insert_sql1 = 'select cr.ImportList_Id ,cr.WrapupData,cr.CallResult, row_number() over (PARTITION BY cr.ImportList_Id  order by cr.CallDateTime desc) as RowNumber  
			from Call_Result_Table_'+cast(@campaign_id as nvarchar)+' cr 
			inner join Outbound_Call_Detail_1000 ocd on cr.DialerRecoveryKey = ocd.RecoveryKey
			inner join Import_List_Table_'+cast(@campaign_id as nvarchar)+' il on il.ImportList_Id = cr.ImportList_Id
		where  il.MapId in ('+@map_id_string+')  and ocd.Status = 12 and ocd.CampaignID = '+cast(@campaign_id as nvarchar)+'';
	--ocd.Status = 12 and
	declare @call_result_condition nvarchar(MAX);
	if(@call_result_string is not null)
	begin
		set @call_result_condition = ' CallResult in ('+@call_result_string+') ';
	end
	declare @wrapup_condition nvarchar(MAX);
	if(@wrapup_string is not null)
	begin 
		set @wrapup_condition = ' WrapupData in  ('+@wrapup_string+') ';
	end
	declare @cr_wr_condition nvarchar(MAX);
	
	if(@call_result_condition is not null or @wrapup_condition is not null)
	begin
		set @cr_wr_condition = '(';	
		if(@call_result_condition is not null)
		begin
			set @cr_wr_condition += @call_result_condition;
			if(@wrapup_condition is not null)
			begin
				set @cr_wr_condition += ' OR '+ @wrapup_condition;
			end
		end
		else if @wrapup_condition is not null
		begin
			set @cr_wr_condition += @wrapup_condition;
		end

		set @cr_wr_condition += ')'
	end
	
	if(@attempt_string is not null)
	begin
		set @insert_sql1 += ' AND il.AttemptsMade '+ @attempt_string;
	end
	--set @insert_sql += ';';
	set @insert_sql += 'update Import_List_Table_'+cast(@campaign_id as nvarchar)+' set Status = 7, ScheduledDateTime = getutcdate() where ImportList_Id in (select ImportList_Id from ('+@insert_sql1+') as temp where RowNumber = 1';
	if(@cr_wr_condition is not null)
	begin
		set @insert_sql+= ' AND ' + @cr_wr_condition;
	end
	set @insert_sql +=');';
	set @insert_sql += 'update ContactList_ImportStatus set Status = 7 where  ListId in ('+@map_id_string+'); update CampaignContact_List set Status = 7 where  CampaignList_Id in ('+@map_id_string+');'; 
	exec(@insert_sql);
	select (@insert_sql);
	--print(@insert_sql);

end




GO
/****** Object:  StoredProcedure [dbo].[SP_Rechurn_Detail_Report]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Rechurn_Detail_Report]
@startdatetime datetime=NULL,              
@enddatetime datetime=NULL

  as

     begin


	    if @startdatetime is NULL and @enddatetime IS NULL

		  begin

		    select Phone01,Phone02,FirstName,LastName,
            case Status  when 1 then 'Pending'
            when 2 then 'Active' 
            when 3 then 'Duplicate' 
            when 4 then 'Invalid' 
            when 5 then 'Valid' 
            when 6 then 'Excluded'
            when 7 then 'Retry' 
            when 8 then 'Processing'
            when 9 then 'Imported'
            when 10 then 'Failed'
            when 11 then 'Deleted'
            when 12 then 'Completed'
            when 13 then 'Expired'
            when 14 then 'InActive'
            when 15 then 'SkippedOrRejected'
            when 16 then 'NotFoundCallResult'
            when 17 then 'Schedule'
            when 18 then 'DailerAutoRetry'
            when 20 then 'GlobalDuplicate'
            end as Status,
            CASE CallResult WHEN 2 THEN 'Error condition while dialing' 
            when 0 then 'Pending'
            when 2 then 'ErrorConditionWhileDialing'
            when 29 then 'NotSupportedByVoiceGateway'
            when 30 then 'NotAuthorizedByVoiceGateway'
            when 31 then 'InvalidSipToVG'
            when 32 then 'CallCancelledByLostConnection'
            WHEN 3 THEN 'Number reported not in service by network'
            WHEN 4 THEN 'No ringback from network when dial attempted'
            WHEN 5 THEN 'Operator intercept returned from network when dial attempted'
            WHEN 6 THEN 'No dial tone when dialer port went off hook'
            WHEN 7 THEN 'Number reported as invalid by the network'
            WHEN 8 THEN 'Customer phone did not answer'
            WHEN 9 THEN 'Customer phone was busy'
            WHEN 10 THEN 'Customer answered and was connected to agent'
            WHEN 11 THEN 'Fax machine detected'
            WHEN 12 THEN 'Answering machine detected'
            WHEN 13 THEN 'Dialer stopped dialing customer due to lack of agents or network stopped dialing before it was complete'
            WHEN 14 THEN 'Customer requested callback'
            WHEN 16 THEN 'Call was abandoned by the dialer due to lack of agents'
            WHEN 17 THEN 'Failed to reserve agent for personal callback'
            WHEN 18 THEN 'Agent has skipped or rejected a preview call'
            WHEN 19 THEN 'Agent has skipped or rejected a preview call with the close option'
            WHEN 20 THEN 'Customer has been abandoned to an IVR'
            WHEN 21 THEN 'Customer dropped call within configured abandoned time'
            WHEN 22 THEN 'Mostly used with TDM switches - network answering machine, such as a network voicemail'
            WHEN 23 THEN 'Number successfully contacted but wrong number'
            WHEN 24 THEN 'Number successfully contacted but reached the wrong person'
            WHEN 25 THEN 'Dialer has flushed this record due to a change in the skillgroup. the campaign, etc.'
            WHEN 26 THEN 'The number was on the do not call list'
            WHEN 27 THEN 'Call disconnected by the carrier or the network while ringing'
            WHEN 28 THEN 'Dead air or low voice volume call'
            ELSE 'Unknown Call Result' end as CallResult,
            AgentName,DialAttempts,ImportAttempts,DialAttempts -1 as Rechurn,SurveyTrackerSFID,CreatedOn,ImportDateTime,LastUpdatedOn
            from Import_List_Table_6740 where ImportAttempts>1 and convert(varchar(10),LastUpdatedOn,120)=convert(varchar(10),getdate(),120)


		  end
		  else
		  begin

		    select Phone01,Phone02,FirstName,LastName,
            case Status  when 1 then 'Pending'
            when 2 then 'Active' 
            when 3 then 'Duplicate' 
            when 4 then 'Invalid' 
            when 5 then 'Valid' 
            when 6 then 'Excluded'
            when 7 then 'Retry' 
            when 8 then 'Processing'
            when 9 then 'Imported'
            when 10 then 'Failed'
            when 11 then 'Deleted'
            when 12 then 'Completed'
            when 13 then 'Expired'
            when 14 then 'InActive'
            when 15 then 'SkippedOrRejected'
            when 16 then 'NotFoundCallResult'
            when 17 then 'Schedule'
            when 18 then 'DailerAutoRetry'
            when 20 then 'GlobalDuplicate'
            end as Status,
            CASE CallResult WHEN 2 THEN 'Error condition while dialing' 
            when 0 then 'Pending'
            when 2 then 'ErrorConditionWhileDialing'
            when 29 then 'NotSupportedByVoiceGateway'
            when 30 then 'NotAuthorizedByVoiceGateway'
            when 31 then 'InvalidSipToVG'
            when 32 then 'CallCancelledByLostConnection'
            WHEN 3 THEN 'Number reported not in service by network'
            WHEN 4 THEN 'No ringback from network when dial attempted'
            WHEN 5 THEN 'Operator intercept returned from network when dial attempted'
            WHEN 6 THEN 'No dial tone when dialer port went off hook'
            WHEN 7 THEN 'Number reported as invalid by the network'
            WHEN 8 THEN 'Customer phone did not answer'
            WHEN 9 THEN 'Customer phone was busy'
            WHEN 10 THEN 'Customer answered and was connected to agent'
            WHEN 11 THEN 'Fax machine detected'
            WHEN 12 THEN 'Answering machine detected'
            WHEN 13 THEN 'Dialer stopped dialing customer due to lack of agents or network stopped dialing before it was complete'
            WHEN 14 THEN 'Customer requested callback'
            WHEN 16 THEN 'Call was abandoned by the dialer due to lack of agents'
            WHEN 17 THEN 'Failed to reserve agent for personal callback'
            WHEN 18 THEN 'Agent has skipped or rejected a preview call'
            WHEN 19 THEN 'Agent has skipped or rejected a preview call with the close option'
            WHEN 20 THEN 'Customer has been abandoned to an IVR'
            WHEN 21 THEN 'Customer dropped call within configured abandoned time'
            WHEN 22 THEN 'Mostly used with TDM switches - network answering machine, such as a network voicemail'
            WHEN 23 THEN 'Number successfully contacted but wrong number'
            WHEN 24 THEN 'Number successfully contacted but reached the wrong person'
            WHEN 25 THEN 'Dialer has flushed this record due to a change in the skillgroup. the campaign, etc.'
            WHEN 26 THEN 'The number was on the do not call list'
            WHEN 27 THEN 'Call disconnected by the carrier or the network while ringing'
            WHEN 28 THEN 'Dead air or low voice volume call'
            ELSE 'Unknown Call Result' end as CallResult,
            AgentName,DialAttempts,ImportAttempts,DialAttempts -1 as Rechurn,SurveyTrackerSFID,CreatedOn,ImportDateTime,LastUpdatedOn
            from Import_List_Table_6740 where ImportAttempts>1 and LastUpdatedOn between @startdatetime and @enddatetime


			
		  end
	 end


GO
/****** Object:  StoredProcedure [dbo].[SP_Rechurn1]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_Rechurn1] 
	@campaign_id int , 
	@map_id_string nvarchar(max),
	@call_result_string nvarchar(max) = null,
	@wrapup_string nvarchar(max) = null,
	@attempt_string nvarchar(max) = null

as begin
	
	declare @insert_sql nvarchar(max);
	set @insert_sql = '
		declare @import_id_table table (ImportList_Id numeric(20,0),WrapupData nvarchar(50),CallResult int, RowNumber int);
		insert into @import_id_table
		select cr.ImportList_Id ,cr.WrapupData,cr.CallResult, row_number() over (PARTITION BY cr.ImportList_Id  order by cr.CallDateTime desc) as RowNumber  
			from Call_Result_Table_'+cast(@campaign_id as nvarchar)+' cr 
			inner join Outbound_Call_Detail_1000 ocd on cr.DialerRecoveryKey = ocd.RecoveryKey
			inner join Import_List_Table_'+cast(@campaign_id as nvarchar)+' il on il.ImportList_Id = cr.ImportList_Id
		where  il.MapId in ('+@map_id_string+')  and ocd.Status = 12 and ocd.CampaignID = '+cast(@campaign_id as nvarchar)+'';
	--ocd.Status = 12 and
	declare @call_result_condition nvarchar(MAX);
	if(@call_result_string is not null)
	begin
		set @call_result_condition = ' CallResult in ('+@call_result_string+') ';
	end
	declare @wrapup_condition nvarchar(MAX);
	if(@wrapup_string is not null)
	begin 
		set @wrapup_condition = ' WrapupData in  ('+@wrapup_string+') ';
	end
	declare @cr_wr_condition nvarchar(MAX);
	
	if(@call_result_condition is not null or @wrapup_condition is not null)
	begin
		set @cr_wr_condition = '(';	
		if(@call_result_condition is not null)
		begin
			set @cr_wr_condition += @call_result_condition;
			if(@wrapup_condition is not null)
			begin
				set @cr_wr_condition += ' OR '+ @wrapup_condition;
			end
		end
		else if @wrapup_condition is not null
		begin
			set @cr_wr_condition += @wrapup_condition;
		end

		set @cr_wr_condition += ')'
	end
	
	if(@attempt_string is not null)
	begin
		set @insert_sql += ' AND il.AttemptsMade '+ @attempt_string;
	end
	set @insert_sql += ';';
	set @insert_sql += 'update Import_List_Table_'+cast(@campaign_id as nvarchar)+' set Status = 7, ScheduledDateTime = getutcdate() where ImportList_Id in (select ImportList_Id from @import_id_table where RowNumber = 1';
	if(@cr_wr_condition is not null)
	begin
		set @insert_sql+= ' AND ' + @cr_wr_condition;
	end
	set @insert_sql +=');';
	set @insert_sql += 'update ContactList_ImportStatus set Status = 7 where  ListId in ('+@map_id_string+'); update CampaignContact_List set Status = 7 where  CampaignList_Id in ('+@map_id_string+');'; 
	exec(@insert_sql);
	select (@insert_sql);
	--print(@insert_sql);

end




GO
/****** Object:  StoredProcedure [dbo].[SP_RechurnCount]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_RechurnCount] 
	@campaign_id int , 
	@map_id_string nvarchar(max),
	@call_result_string nvarchar(max) = null,
	@wrapup_string nvarchar(max) = null,
	@attempt_string nvarchar(max) = null

as begin
	
	declare @insert_sql nvarchar(max);
	set @insert_sql = '
		declare @import_id_table table (ImportList_Id numeric(20,0),WrapupData nvarchar(50),CallResult int, RowNumber int);
		insert into @import_id_table
		select cr.ImportList_Id ,cr.WrapupData,cr.CallResult, row_number() over (PARTITION BY cr.ImportList_Id  order by cr.CallDateTime desc) as RowNumber  
			from Call_Result_Table_'+cast(@campaign_id as nvarchar)+' cr 
			inner join Outbound_Call_Detail_1000 ocd on cr.DialerRecoveryKey = ocd.RecoveryKey
			inner join Import_List_Table_'+cast(@campaign_id as nvarchar)+' il on il.ImportList_Id = cr.ImportList_Id
		where  il.MapId in ('+@map_id_string+') 
	';

	declare @call_result_condition nvarchar(MAX);
	if(@call_result_string is not null)
	begin
		set @call_result_condition = ' CallResult in ('+@call_result_string+') ';
	end
	declare @wrapup_condition nvarchar(MAX);
	if(@wrapup_string is not null)
	begin 
		set @wrapup_condition = ' WrapupData in  ('+@wrapup_string+') ';
	end
	declare @cr_wr_condition nvarchar(MAX);
	
	if(@call_result_condition is not null or @wrapup_condition is not null)
	begin
		set @cr_wr_condition = '(';	
		if(@call_result_condition is not null)
		begin
			set @cr_wr_condition += @call_result_condition;
			if(@wrapup_condition is not null)
			begin
				set @cr_wr_condition += ' OR '+ @wrapup_condition;
			end
		end
		else if @wrapup_condition is not null
		begin
			set @cr_wr_condition += @wrapup_condition;
		end

		set @cr_wr_condition += ')'
	end
	
	if(@attempt_string is not null)
	begin
		set @insert_sql += ' AND il.AttemptsMade '+ @attempt_string;
	end
	set @insert_sql += ';';
	set @insert_sql += 'select count(*) as TotalCount from @import_id_table where RowNumber = 1 ';
	if(@cr_wr_condition is not null)
	begin
		set @insert_sql+= ' AND ' + @cr_wr_condition;
	end
	set @insert_sql +='';
	exec(@insert_sql);
	print @insert_sql;
end




GO
/****** Object:  StoredProcedure [dbo].[Sp_RemoveAgentFromDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[Sp_RemoveAgentFromDealer] @mapId int as begin
	Update DealerExtraDetails set  IsActive=0, LastUpdatedOn = getutcdate() WHERE MapId = @mapId
 end








GO
/****** Object:  StoredProcedure [dbo].[SP_RemoveCampaignGroupMapping]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_RemoveCampaignGroupMapping] @group_Id int , @department_Id int as
begin
delete CampaignGroupMaster where GroupId=@group_Id and DepartmentId=@department_Id
end


GO
/****** Object:  StoredProcedure [dbo].[SP_RemoveCampaignState]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_RemoveCampaignState] @tenant_id int, @campaign_id int
as begin
	update CampaignState set IsDeleted = 1 where CampaignId = @campaign_id and TenantId = @tenant_id
end












GO
/****** Object:  StoredProcedure [dbo].[SP_RemoveExtraDetailsState]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_RemoveExtraDetailsState] @tenant_id int, @campaign_id int
as begin
	update CampaignExtraDetails set IsActive = 0, LastUpdatedOn=GETUTCDATE() where CampaignId = @campaign_id and TenantId = @tenant_id
end






GO
/****** Object:  StoredProcedure [dbo].[Sp_RemoveMapFromDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  procedure [dbo].[Sp_RemoveMapFromDealer] @mapId int as begin
	Delete from  DealerExtraDetails  WHERE MapId = @mapId
 end









GO
/****** Object:  StoredProcedure [dbo].[SP_SaveCampaignGroupMapping]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_SaveCampaignGroupMapping] 
	@tenant_id int, 
	@department_id int, 
	@group_id int,
	@campaign_ids int

as begin
	declare @output table(Id int)
	insert into CampaignGroupMaster 
		(CampaignId,GroupId,DepartmentId,TenantId,IsActive,CreatedOn)
	output inserted.Id into @output
	values
		(@campaign_ids,@group_id,@department_id,@tenant_id,1,getutcdate());
	select * from @output
end


GO
/****** Object:  StoredProcedure [dbo].[Sp_sequenceAddContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Sp_sequenceAddContactList]
    @source_id INT,
    @details XML, 
    @name NVARCHAR(50), 
    @purpose INT = 0,
    @filter XML,
    @AutoGenerated BIT, 
    @dealerId INT
AS
BEGIN
    -- Start a transaction
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Check for duplicates (only considering Name must be unique)
        IF NOT EXISTS (SELECT 1 FROM Contact_List WHERE Name = @name)
        BEGIN
            -- Declare a table variable to capture the inserted Id
            DECLARE @InsertedIds TABLE (Id INT);

            -- Insert the record into Contact_List and output the Id to @InsertedIds
            INSERT INTO Contact_List (SourceId, Details, Purpose, CreatedOn, Name, Filters, AutoGenerated, DealerId)
            OUTPUT INSERTED.Id INTO @InsertedIds
            VALUES (@source_id, @details, @purpose, GETUTCDATE(), @name, @filter, @AutoGenerated, @dealerId);

            -- Return the inserted Id(s)
            SELECT * FROM @InsertedIds;
        END
        ELSE
        BEGIN
            -- Handle case where a record with the same Name already exists
            PRINT 'Record already exists with the same Name.';
        END

        -- Commit the transaction if everything is successful
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Rollback transaction in case of error
        ROLLBACK TRANSACTION;

        -- Get error details
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;
        DECLARE @ErrorState INT;

        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();

        -- Raise the error for external handling
        RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[SP_Stuck_Records]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[SP_Stuck_Records]

as
begin
CREATE TABLE #XMLTable (CampaignList_Id int ,attribute varchar(30), operator varchar(30) , value varchar(30) )

INSERT INTO #XMLTable (CampaignList_Id,attribute , operator , value )
SELECT
s.CampaignList_Id,
m.c.value('@attribute', 'varchar(max)') as attribute ,
m.c.value('@operator', 'varchar(max)') as operator,
m.c.value('@value', 'varchar(max)') as value
from CampaignContact_List as s
outer apply s.Filters.nodes('filter/conditions/condition') as m(c)


SELECT CCL.CampaignList_Id , CED.Name as Campaign_Name , CL.Name as List_Name ,TS.value ,
delay=case when CLI.LastAttemptedOn!=null then (case when -DATEDIFF(MINUTE, getutcdate() , CLI.LastAttemptedOn)>15 then 1 else 0 end) else (case when -DATEDIFF(MINUTE, getutcdate() , CLI.PreProcessedOn)>15 then 1 else 0 end )end,
CLI.Lastattemptedon,CCL.CreatedOn

from CampaignContact_List CCL
INNER JOIN Contact_List CL ON CCL.ListId=CL.Id
INNER JOIN ContactList_ImportStatus CLI ON CCL.CampaignList_Id=CLI.ListId
INNER JOIN CampaignExtraDetails CED ON CCL.CampaignId=CED.CampaignId
INNER JOIN #XMLTable TS ON CCL.CampaignList_Id=TS.CampaignList_Id
WHERE CCL.Status IN(1,5,7) --and -DATEDIFF(MINUTE, getutcdate() , CL.LastAttemptedOn)>15
AND CCL.IsActive=1 AND CL.IsActive=1 and CED.IsActive=1



DROP TABLE #XMLTable
end




GO
/****** Object:  StoredProcedure [dbo].[SP_StuckAssignedList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[SP_StuckAssignedList]

as
begin

select CCL.CampaignId,  CCL.ListId,CED.Name as Campaign_Name,CL.Name as List_Name,CCL.CampaignList_Id as MapId, DEPT.DealerName as Dealer
from CampaignContact_List as CCL
inner join CampaignExtraDetails as CED on CCL.CampaignId=CED.CampaignId
inner join Contact_List as CL on CCL.ListId=CL.Id
inner join Dealer as DEPT on CED.DealerId=DEPT.DealerId
where CCL.Status =1 and -DATEDIFF(HOUR, getutcdate() , CCL.CreatedOn)>2 and CL.IsActive=1

end


GO
/****** Object:  StoredProcedure [dbo].[SP_UnAssignContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UnAssignContactList]  @campaignList_id int
as begin
	update CampaignContact_List set IsActive = 0 where CampaignList_Id = @campaignList_id
end






GO
/****** Object:  StoredProcedure [dbo].[SP_UnGroupCampaigns]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[SP_UnGroupCampaigns]
@campaign_Id int, @department_Id int
as
begin
delete from CampaignGroupMaster where CampaignId=@campaign_Id and DepartmentId=@department_Id
end


GO
/****** Object:  StoredProcedure [dbo].[SP_Unicamp_Calldata]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_Unicamp_Calldata]
@StartDate DateTime,
@EndDate DateTime,
@page_no int,
@records_per_page int,
@sort_by nvarchar(50) = 'CampaignID' ,
@direction nvarchar(4)='DESC',
@total_records int output
As begin
Declare @dynamicSql nvarchar(MAX);
Declare @queryCount nvarchar(max);
				set @dynamicSql = '
					WITH cte AS( SELECT ROW_NUMBER() OVER(ORDER BY CampaignID '+@direction+') AS RowNumber ,* from  OPENQUERY([192.168.1.34] ,''select Distinct CampaignID ,CampaignName, Sum(AnsweredCalls)AnsweredCalls ,
					Sum(DialedCalls)DialedCalls, Sum(Abandoned_lackofagents)Abandoned_lackofagents ,
					Sum(Abandoned_At_IVR)Abandoned_At_IVR , Sum(Customer_Dropped_Call_Within_Configured_Abandoned_time)Customer_Dropped_Call_Within_Configured_Abandoned_time from
                    ( select DD.CampaignID ,C.CampaignName, Case when CallResult = 10 then count(*)
                     else 0 end as AnsweredCalls , Count(RecoveryKey) as DialedCalls,
                     Case when CallResult = 16 then count(*)
                     else 0 end as Abandoned_lackofagents  , 
                     Case when CallResult = 20 then count(*)
                     else 0 end as Abandoned_At_IVR ,
                     Case when CallResult = 21 then count(*)
                     else 0 end as Customer_Dropped_Call_Within_Configured_Abandoned_time 
                     from [ins11_hds].[dbo].Dialer_Detail DD left Outer join [ins11_awdb].[dbo].Campaign C on (DD.CampaignID = C.CampaignID) where DateTime between '''''+cast(@StartDate as nvarchar(50))+''''' and '''''+cast(@EndDate as nvarchar(50))+'''''   
                     Group by DD.CampaignID ,C.CampaignName, CallResult
                     ) A Group by CampaignID,CampaignName ''
                     ))
					 
					 
					  SELECT * FROM cte WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+' ';
					 
				set @queryCount = '
					Select @total_records = Count(*) from  OPENQUERY([192.168.1.34] ,''select Distinct CampaignID , Sum(AnsweredCalls)AnsweredCalls ,
					Sum(DialedCalls)DialedCalls, Sum(Abandoned_lackofagents)Abandoned_lackofagents ,
					Sum(Abandoned_At_IVR)Abandoned_At_IVR , Sum(Customer_Dropped_Call_Within_Configured_Abandoned_time)Customer_Dropped_Call_Within_Configured_Abandoned_time from
                    ( select DD.CampaignID , Case when CallResult = 10 then count(*)
                     else 0 end as AnsweredCalls , Count(RecoveryKey) as DialedCalls,
                     Case when CallResult = 16 then count(*)
                     else 0 end as Abandoned_lackofagents  , 
                     Case when CallResult = 20 then count(*)
                     else 0 end as Abandoned_At_IVR ,
                     Case when CallResult = 21 then count(*)
                     else 0 end as Customer_Dropped_Call_Within_Configured_Abandoned_time 
                     from [ins11_hds].[dbo].Dialer_Detail DD where DateTime between '''''+cast(@StartDate as nvarchar(50))+''''' and '''''+cast(@EndDate as nvarchar(50))+'''''   
                     Group by DD.CampaignID , CallResult
                     ) A Group by CampaignID ''
                     )';
				
				
				
				exec(@dynamicSql);
				 exec sp_executesql @queryCount , N'@total_records int output',@total_records output  ;

End






GO
/****** Object:  StoredProcedure [dbo].[SP_Unicamp_Calldata_Test]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[SP_Unicamp_Calldata_Test]
@StartDate DateTime,
@EndDate DateTime,
@page_no int,
@records_per_page int,
@sort_by nvarchar(50) = 'CampaignID' ,
@direction nvarchar(4)='DESC',
@total_records int output
As begin
Declare @dynamicSql nvarchar(MAX);
Declare @queryCount nvarchar(max);
				set @dynamicSql = '
					WITH cte AS( SELECT ROW_NUMBER() OVER(ORDER BY CampaignID '+@direction+') AS RowNumber ,* from  OPENQUERY([192.168.1.34] ,''select Distinct CampaignID ,CampaignName, Sum(AnsweredCalls)AnsweredCalls ,
					Sum(DialedCalls)DialedCalls, Sum(Abandoned_lackofagents)Abandoned_lackofagents ,
					Sum(Abandoned_At_IVR)Abandoned_At_IVR , Sum(Customer_Dropped_Call_Within_Configured_Abandoned_time)Customer_Dropped_Call_Within_Configured_Abandoned_time from
                    ( select DD.CampaignID ,C.CampaignName, Case when CallResult = 10 then count(*)
                     else 0 end as AnsweredCalls , Count(RecoveryKey) as DialedCalls,
                     Case when CallResult = 16 then count(*)
                     else 0 end as Abandoned_lackofagents  , 
                     Case when CallResult = 20 then count(*)
                     else 0 end as Abandoned_At_IVR ,
                     Case when CallResult = 21 then count(*)
                     else 0 end as Customer_Dropped_Call_Within_Configured_Abandoned_time 
                     from [ins11_hds].[dbo].Dialer_Detail DD inner join [ins11_awdb].[dbo].Campaign C on (DD.CampaignID = C.CampaignID) where DateTime between '''''+cast(@StartDate as nvarchar(50))+''''' and '''''+cast(@EndDate as nvarchar(50))+'''''   
                     Group by DD.CampaignID ,C.CampaignName, CallResult
                     ) A Group by CampaignID,CampaignName ''
                     ))
					 
					 
					  SELECT * FROM cte WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+' ';
					 
				set @queryCount = '
					Select @total_records = Count(*) from  OPENQUERY([192.168.1.34] ,''select Distinct CampaignID , Sum(AnsweredCalls)AnsweredCalls ,
					Sum(DialedCalls)DialedCalls, Sum(Abandoned_lackofagents)Abandoned_lackofagents ,
					Sum(Abandoned_At_IVR)Abandoned_At_IVR , Sum(Customer_Dropped_Call_Within_Configured_Abandoned_time)Customer_Dropped_Call_Within_Configured_Abandoned_time from
                    ( select DD.CampaignID , Case when CallResult = 10 then count(*)
                     else 0 end as AnsweredCalls , Count(RecoveryKey) as DialedCalls,
                     Case when CallResult = 16 then count(*)
                     else 0 end as Abandoned_lackofagents  , 
                     Case when CallResult = 20 then count(*)
                     else 0 end as Abandoned_At_IVR ,
                     Case when CallResult = 21 then count(*)
                     else 0 end as Customer_Dropped_Call_Within_Configured_Abandoned_time 
                     from [ins11_hds].[dbo].Dialer_Detail DD where DateTime between '''''+cast(@StartDate as nvarchar(50))+''''' and '''''+cast(@EndDate as nvarchar(50))+'''''   
                     Group by DD.CampaignID , CallResult
                     ) A Group by CampaignID ''
                     )';
				
				
				
				exec(@dynamicSql);
				 exec sp_executesql @queryCount , N'@total_records int output',@total_records output  ;

End






GO
/****** Object:  StoredProcedure [dbo].[SP_Unicamp_Calldata_Test1]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_Unicamp_Calldata_Test1]
@StartDate DateTime,
@EndDate DateTime,
@total_records int output

As begin
declare @dynamicSql nvarchar(MAX);
set @dynamicSql = '
					Select * from  OPENQUERY([192.168.1.34] ,''select Distinct CampaignID , Sum(AnsweredCalls)AnsweredCalls ,
					Sum(DialedCalls)DialedCalls, Sum(Abandoned_lackofagents)Abandoned_lackofagents ,
					Sum(Abandoned_At_IVR)Abandoned_At_IVR , Sum(Customer_Dropped_Call_Within_Configured_Abandoned_time)Customer_Dropped_Call_Within_Configured_Abandoned_time from
                    ( select DD.CampaignID , Case when CallResult = 10 then count(*)
                     else 0 end as AnsweredCalls , Count(RecoveryKey) as DialedCalls,
                     Case when CallResult = 16 then count(*)
                     else 0 end as Abandoned_lackofagents  , 
                     Case when CallResult = 20 then count(*)
                     else 0 end as Abandoned_At_IVR ,
                     Case when CallResult = 21 then count(*)
                     else 0 end as Customer_Dropped_Call_Within_Configured_Abandoned_time 
                     from [ins11_awdb].[dbo].Dialer_Detail DD where DateTime between '''''+Convert(varchar,@StartDate,103)+''''' and '''''+Convert(varchar,@EndDate,103)+'''''   
                     Group by DD.CampaignID , CallResult
                     ) A Group by CampaignID ''
                     )';
					exec(@dynamicSql);
End






GO
/****** Object:  StoredProcedure [dbo].[SP_Unicamp_StateTime]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_Unicamp_StateTime]
@StartDate DateTime,
@EndDate DateTime,
@page_no int,
@records_per_page int,
@sort_by nvarchar(50) = 'DateTime' ,
@direction nvarchar(4)='DESC',
@total_records int output
as begin  
declare @dynamicSql nvarchar(MAX);
declare @dynamicSqlCount as nvarchar(max);
set @dynamicSql = '
				WITH cte AS( SELECT ROW_NUMBER() OVER(ORDER BY DateTime '+@direction+') AS RowNumber ,* from  OPENQUERY([192.168.1.34] ,''select distinct A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName ,ASGI.DateTime,
Sum(ReserveCallsTime)ReserveCallsTime , Sum(ReserveCallsTalkTime)ReserveCallsTalkTime , 
Sum(ReserveCallsOnHoldTime)ReserveCallsOnHoldTime , Sum(TalkOutTime)TalkTime 
from [ins11_awdb].[dbo]. Agent_Skill_Group_Interval ASGI 
inner join [ins11_awdb].[dbo].Agent A on (ASGI.SkillTargetID = A.SkillTargetID) 
where ASGI.DateTime between '''''+cast(@StartDate as nvarchar(50))+''''' and '''''+cast(@EndDate as nvarchar(50))+'''''
Group by A.PeripheralNumber,EnterpriseName,DateTime ''
                     ))
SELECT * FROM cte WHERE RowNumber BETWEEN (('+cast(@page_no as varchar)+'-1)*'+cast(@records_per_page as varchar)+')+1 
 AND '+cast(@records_per_page as varchar)+' * ('+cast(@page_no as varchar)+') ORDER BY '+@sort_by+' '+@direction+' ';					 
					
set	@dynamicSqlCount='select @total_records = Count(*) from  OPENQUERY([192.168.1.34] ,''select distinct A.PeripheralNumber as AgentID , A.EnterpriseName as AgentName ,ASGI.DateTime,
Sum(ReserveCallsTime)ReserveCallsTime , Sum(ReserveCallsTalkTime)ReserveCallsTalkTime , 
Sum(ReserveCallsOnHoldTime)ReserveCallsOnHoldTime , Sum(TalkOutTime)TalkTime 
from [ins11_awdb].[dbo]. Agent_Skill_Group_Interval ASGI 
inner join [ins11_awdb].[dbo].Agent A on (ASGI.SkillTargetID = A.SkillTargetID) 
where ASGI.DateTime between '''''+cast(@StartDate as nvarchar(50))+''''' and '''''+cast(@EndDate as nvarchar(50))+'''''
Group by A.PeripheralNumber,EnterpriseName,DateTime ''
                     )';				 
exec(@dynamicSql);
exec sp_executesql @dynamicSqlCount , N'@total_records int output',@total_records output  ;


end 






GO
/****** Object:  StoredProcedure [dbo].[SP_Update_AgentScript]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Update_AgentScript] @script_id int,@script_name nvarchar(100),@script_body nvarchar(MAX),@script_enable bit as
BEGIN
		Update AgentScripts SET AgentScriptName  = @script_name, ScriptBody=@script_body, Enable=@script_enable WHERE AgentScriptID =@script_id
End











GO
/****** Object:  StoredProcedure [dbo].[Sp_Update_CampaignContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Update_CampaignContactList] @CampaignList_Id int,@campaign_Id int,@listid int, @scheduleStart datetime ,@timeZone nvarchar(100),@recurrence int,@recurrence_Interval numeric(10,2),@filterDuplicate bit,@filterDnc bit,@keepheaders bit,@status int,@accountNumber nvarchar(100),@firstName nvarchar(100),@lastName nvarchar(100),@phone01 nvarchar(100),@phone02 nvarchar(100),@phone03 nvarchar(100),@phone04 nvarchar(100),@phone05 nvarchar(100),@phone06 nvarchar(100),@phone07 nvarchar(100),@phone08 nvarchar(100),@phone09 nvarchar(100),@phone10 nvarchar(100),@timeZone_bias nvarchar(100),@dstobserve nvarchar(100),@overwriteData bit,@target_country nvarchar(4), @recurrence_unit int = 2 , @extra_details xml
as
begin
update CampaignContact_List set CampaignId=@campaign_Id,ListId=@listid,TargetCountry = @target_country, ScheduleStart=@scheduleStart,TimeZone=@timeZone,Recurrence=@recurrence,Recurrence_Interval=@recurrence_Interval,FilterDuplicate=@filterDuplicate,FilterDNC=@filterDnc,KeepHeaders=@keepheaders,Status=@status,AccountNumber=@accountNumber,FirstName=@firstName,LastName=@lastName,Phone01=@phone01,Phone02=@phone02,Phone03=@phone03,Phone04=@phone04,Phone05=@phone05,Phone06=@phone06,Phone07=@phone07,Phone08=@phone08,Phone09=@phone09,Phone10=@phone10,TimeZone_bias=@timeZone_bias,DstObserve=@dstobserve,LastUpdatedOn=getutcdate(),OverwriteData = @overwriteData, RecurrenceUnit = @recurrence_unit ,ExtraDetails =@extra_details
where CampaignList_Id = @CampaignList_Id
 end


















GO
/****** Object:  StoredProcedure [dbo].[Sp_Update_CampaignContactList_LS]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_Update_CampaignContactList_LS] @CampaignList_Id int,@campaign_Id int,@listid int, @scheduleStart datetime ,@timeZone nvarchar(100),@recurrence int,@recurrence_Interval numeric(10,2),@filterDuplicate bit,@filterDnc bit,@keepheaders bit,@status int,@laststatus int,@accountNumber nvarchar(100),@firstName nvarchar(100),@lastName nvarchar(100),@phone01 nvarchar(100),@phone02 nvarchar(100),@phone03 nvarchar(100),@phone04 nvarchar(100),@phone05 nvarchar(100),@phone06 nvarchar(100),@phone07 nvarchar(100),@phone08 nvarchar(100),@phone09 nvarchar(100),@phone10 nvarchar(100),@timeZone_bias nvarchar(100),@dstobserve nvarchar(100),@overwriteData bit,@target_country nvarchar(4), @recurrence_unit int = 2 , @extra_details xml
as
begin
update CampaignContact_List set CampaignId=@campaign_Id,ListId=@listid,TargetCountry = @target_country, ScheduleStart=@scheduleStart,TimeZone=@timeZone,Recurrence=@recurrence,Recurrence_Interval=@recurrence_Interval,FilterDuplicate=@filterDuplicate,FilterDNC=@filterDnc,KeepHeaders=@keepheaders,Status=@status,LastStatus=@laststatus, AccountNumber=@accountNumber,FirstName=@firstName,LastName=@lastName,Phone01=@phone01,Phone02=@phone02,Phone03=@phone03,Phone04=@phone04,Phone05=@phone05,Phone06=@phone06,Phone07=@phone07,Phone08=@phone08,Phone09=@phone09,Phone10=@phone10,TimeZone_bias=@timeZone_bias,DstObserve=@dstobserve,LastUpdatedOn=getutcdate(),OverwriteData = @overwriteData, RecurrenceUnit = @recurrence_unit ,ExtraDetails =@extra_details
where CampaignList_Id = @CampaignList_Id
 end



















GO
/****** Object:  StoredProcedure [dbo].[Sp_Update_ContactMapAppendConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[Sp_Update_ContactMapAppendConfig] @CampaignId int,@ParentMapId int,@AppendedListId int,@Status int,@CreatedOn datetime, @Id int
	 as
BEGIN
		Update ContactMapAppendConfig SET CampaignId = @CampaignId, ParentMapId=@ParentMapId, AppendedListId=@AppendedListId,Status=@Status,CreatedOn=@CreatedOn,LastUpdatedOn=GETUTCDATE() WHERE Id =@Id
End




GO
/****** Object:  StoredProcedure [dbo].[SP_Update_DNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Update_DNC] @DNC_Id INT,@PhoneNumber nvarchar(100),@CampaignId int AS
BEGIN
	UPDATE CustomDNC SET  PhoneNumber = @PhoneNumber,CampaignId=@CampaignId WHERE DNCId = @DNC_Id
END


	



















GO
/****** Object:  StoredProcedure [dbo].[SP_Update_EmailConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Update_EmailConfig] @config_id int,@name nvarchar(100),@host nvarchar(MAX),@smtp_port int, @username nvarchar(MAX), @password nvarchar(MAX),
	@from_address nvarchar(MAX), @ssl bit as
BEGIN
		Update EmailConfiguration SET Name = @name, EmailHost=@host, SMTPPort=@smtp_port,EmailUsername=@username,EmailPassword=@password,FromAddress=@from_address,IsSSL=@ssl  WHERE EmailConfigID =@config_id
End
	













GO
/****** Object:  StoredProcedure [dbo].[SP_Update_EmailTemplate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE PROCEDURE [dbo].[SP_Update_EmailTemplate] @template_id int,@template_name nvarchar(100),@email_body nvarchar(MAX) as
BEGIN
		Update EmailTemplates SET EmailTemplateName  = @template_name, EmailBody=@email_body WHERE EmailTemplateID =@template_id
End











GO
/****** Object:  StoredProcedure [dbo].[Sp_Update_MultiContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_Update_MultiContactList] @status int,@multiListId int
as
begin
update MultiContactListConfig set Status=@status where MultiListId=@multiListId
 end










GO
/****** Object:  StoredProcedure [dbo].[Sp_Update_PreviewCampaignContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_Update_PreviewCampaignContactList]@status int,@CampaignList_Id int
as
begin
update PreviewCampaignContact_List set Status=@status
where CampaignList_Id = @CampaignList_Id
 end








GO
/****** Object:  StoredProcedure [dbo].[Sp_Update_PreviewCampaignImportList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[Sp_Update_PreviewCampaignImportList] @Id int,@status int,@importedTime datetime = null,@dialAtempts int = null
as begin

update PreviewCampaignImportList set Status=@status ,ImportedTime=@importedTime,DialAtempts=@dialAtempts where ID=@Id

 end






GO
/****** Object:  StoredProcedure [dbo].[Sp_update_RechurnPolicy]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_update_RechurnPolicy] 
@Id int,
@name nvarchar(max),
@description nvarchar(max)= null,
@isManual bit,
@Status int,
@dialAttempt int = null,
@dialAttemptCondition int = null


as
begin

update RechurnPolicy set IsManual=@isManual, Name=@name,Description=@description,Status=@Status,LastUpdatedOn=GETUTCDATE(),DialAttempt=@dialAttempt,DialAttemptCondition=@dialAttemptCondition where Id=@Id

 end





GO
/****** Object:  StoredProcedure [dbo].[SP_Update_RecurrenceSchedule]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_Update_RecurrenceSchedule] 

 @Id int ,
                        @name nvarchar(max) ,
                        @description nvarchar(max),
                        @scheduleType int,
                        @frequency int,
                        @recurenceInterval int,
                        @recurenceUnit int,
                        @startDateTime datetime ,
                        @endDateTime datetime,
                        @status int ,
						@NextIterationDate date 
as begin 

update RecurrenceSchedule set Name=@name,Description=@description,ScheduleType=@scheduleType,Frequency=@frequency, RecurrenceInterval=@recurenceInterval, RecurrenceUnit=@recurenceUnit, StartDateTime=@startDateTime, EndDateTime=@endDateTime, Status=@status, LastUpdatedOn=getUtcdate(), NextIterationDate=@NextIterationDate where Id=@Id
end





GO
/****** Object:  StoredProcedure [dbo].[SP_Update_SMSConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE PROCEDURE [dbo].[SP_Update_SMSConfig] @config_id int,@config_name nvarchar(100),@type int,@configuration xml as
BEGIN
		Update SMSConfiguration SET SMSConfigName  = @config_name,Type=@type,Configuration=@configuration,LastUpdatedOn=GETDATE() WHERE SMSConfigId =@config_id
End













GO
/****** Object:  StoredProcedure [dbo].[SP_Update_SMSTemplate]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	CREATE PROCEDURE [dbo].[SP_Update_SMSTemplate] @template_id int,@template_name nvarchar(100),@sms_msg nvarchar(MAX) as
BEGIN
		Update SMSTemplates SET SMSTemplateName  = @template_name, SMSMessage=@sms_msg WHERE SMSTemplateID =@template_id
End











GO
/****** Object:  StoredProcedure [dbo].[SP_Update_User]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_Update_User] @user_id INT, @user_name NVARCHAR(150), @user_password NVARCHAR(150),@user_role_id INT,@user_client_id INT AS
BEGIN
	declare @old_password nvarchar(MAX);
	select @old_password = Password from UserMaster where UserId = @user_id;
	if(@old_password != @user_password)
	begin
		UPDATE UserMaster SET Username = @user_name, Password = @user_password, 
			Role = @user_role_id,TenantId=@user_client_id, LastUpdatedOn = GETUTCDATE(), PasswordUpdatedOn = GETUTCDATE() 
		WHERE UserId = @user_id
	end
	else
	begin
		UPDATE UserMaster SET Username = @user_name, Password = @user_password, 
			Role = @user_role_id,TenantId=@user_client_id, LastUpdatedOn = GETUTCDATE()
		WHERE UserId = @user_id
	end
END















GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateBulkCallback]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateBulkCallback] @campaign int, @agent int, @file_path nvarchar(100), @overwrite bit, @processed bit,@delimiter char(1), @id int as 
begin
	update BulkCallback set CampaignId = @campaign, Delimiter = @delimiter, AgentSkillTargetId = @agent, FilePath = @file_path, OverwriteData = @overwrite, IsProcessed = @processed where BulkId = @id
end

















GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateCallback]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[SP_UpdateCallback]
@id int, @phonenumber nvarchar(50),@callbackDateTime datetime,@lastUpdatedOn datetime
as
begin
update CallbackMaster set PhoneNumber=@phonenumber , CallbackScheduledDateTime=@callbackDateTime,LastUpdatedOn= @lastUpdatedOn where Id=@id 
end


GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateCampaignGroupMapping]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_UpdateCampaignGroupMapping] @campaignId int,@groupId int as
begin
	update CampaignGroupMaster  set GroupId=@groupId 
	where CampaignId = @campaignId
end


GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateCBMConfig]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateCBMConfig] 
	@tenant_id int, @campaign_id int, @level int, @identifier nvarchar(20), @call_result_map xml, @wrapup_map xml, @max_attempts int
as
begin
	update CBMConfig set 
		Level = @level, 
		IdentifierField = @identifier,
		CallResultMap = @call_result_map, 
		WrapupMap = @wrapup_map, 
		MaximumAttempts = @max_attempts
	where CampaignId = @campaign_id and TenantId = @tenant_id 
end











GO
/****** Object:  StoredProcedure [dbo].[Sp_UpdateContactList]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_UpdateContactList] @id int,@dealerId int, @source_id int,@details nvarchar(1000) , @name nvarchar(50), @purpose int = 0, @filters xml
as
begin
update  Contact_List set DealerId=@dealerId,SourceId=@source_id, Details=@details, LastUpdatedOn=getutcdate(), Name = @name, Purpose = @purpose, Filters = @filters where  Id=@id;
 end










GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateContactListSequence]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UpdateContactListSequence]
@tenant_id int,
	@name nvarchar(100),
	@sequence_id int,
	@campaign_id int,
	@source_id int,
	@template_path nvarchar(MAX) ,
	@delimiter nvarchar(1),
	@headers bit,
	@filename_format nvarchar(MAX),
	@daily_iterations int ,
	@interval numeric(10,2),
	@interval_unit int,
	@interval_in_minutes numeric(10,0) ,
	@start_time datetime =null ,
	@time_zone nvarchar(255),
	@target_country nvarchar(4),
	@status int,
	@placeholder_map xml = null,
	@header_map xml = null ,
	@next_iteration datetime = null,
	@filters xml = null
as begin
	
	update ContactListSequence 
		set CampaignId = @campaign_id ,
			Name = @name,
			SourceId = @source_id,
			TemplatePath = @template_path,
			Delimiter = @delimiter,
			Headers = @headers,
			FileNameFormat = @filename_format,
			MaximumDailyIterations = @daily_iterations,
			Interval = @interval,
			IntervalUnit = @interval_unit,
			IntervalInMinutes = @interval_in_minutes,
			StartDateTime = @start_time,
			TimeZone = @time_zone,
			TargetCountry = @target_country,
			Status = @status,
			PlaceholderMap = @placeholder_map,
			HeaderMap = @header_map,
			NextIterationDate = @next_iteration,
			Filters = @filters,
			LastUpdatedOn = GETUTCDATE()
		where Id = @sequence_id
end










GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateContactListSequenceIteration]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateContactListSequenceIteration] 
	@iteration_id int,
	@sequence_id int,
	@map_id int, 
	@list_id int,
	@generated_filename nvarchar(max),
	@placeholder_map xml = null
as begin 
	update ContactListSequenceIteration
		set SequenceId = @sequence_id,
			MapId = @map_id, 
			ListId = @list_id, 
			AutogeneratedFileName = @generated_filename, 
			PlaceholderMap = @placeholder_map,
			LastUpdatedOn = getutcdate()
		where Id = @iteration_id
end








GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateContactMapGroup]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateContactMapGroup] 
    @Id Int,
	@campaign_id int,
	@list_id int, 
	@schedule_start datetime,
	@time_zone nvarchar(100),
	@recurrence int,
	@recurrence_interval numeric(10,2),
	@recurrence_unit int = 2,
	@filter_duplicate bit,
	@filter_dnc bit,
	@keep_headers bit,
	@status int,
	@account_number nvarchar(100),
	@first_name nvarchar(100),
	@last_name nvarchar(100),
	@phone01 nvarchar(100),
	@phone02 nvarchar(100) = null,
	@phone03 nvarchar(100) = null,
	@phone04 nvarchar(100) = null,
	@phone05 nvarchar(100) = null,
	@phone06 nvarchar(100) = null,
	@phone07 nvarchar(100) = null,
	@phone08 nvarchar(100) = null,
	@phone09 nvarchar(100) = null,
	@phone10 nvarchar(100) = null,
	@timezone_bias nvarchar(100),
	@dst_observed nvarchar(100),
	@overwrite_data bit,
	@duplicate_rules xml,
	@target_country nvarchar(4),
	@extra_details xml,
	@extra_column1 nvarchar(255),
	@extra_column2 nvarchar(255),
	@extra_column3 nvarchar(255),
	@extra_column4 nvarchar(255),
	@extra_column5 nvarchar(255),
	@extra_column6 nvarchar(255),
	@extra_column7 nvarchar(255),
	@extra_column8 nvarchar(255),
	@extra_column9 nvarchar(255),
	@extra_column10 nvarchar(255),
	@extra_column11 nvarchar(255),
	@extra_column12 nvarchar(255),
	@extra_column13 nvarchar(255),
	@extra_column14 nvarchar(255),
	@extra_column15 nvarchar(255),
	@filters xml,
	@dialing_priority int,
	@group_details xml,
	@parent_id int = null
as
begin

Update ContactMapGroup set 
	CampaignId = @campaign_id,
	ListId =@list_id,
	TargetCountry =@target_country,
	ScheduleStart = @schedule_start,
	TimeZone = @time_zone,
	Recurrence = @recurrence,
	RecurrenceInterval = @recurrence_interval ,
	RecurrenceUnit = @recurrence_unit,
	FilterDuplicate = @filter_duplicate,
	FilterDNC = @filter_dnc,
	KeepHeaders =@keep_headers ,
	DialingPriority = @dialing_priority,
	ParentId= @parent_id,
	Status = @status,
	GroupDetails= @group_details,
	Phone01= @phone01,
	AccountNumber= @account_number,
	FirstName = @first_name,
	LastName = @last_name,
	Phone02= @phone02,
	Phone03 = @phone03,
	Phone04 = @phone04 ,
	Phone05 = @phone05,
	Phone06 = @phone06,
	Phone07 = @phone07,
	Phone08 = @phone08,
	Phone09 = @phone09 ,
	Phone10 = @phone10 ,
	TimeZoneBias = @timezone_bias,
	DstObserved = @dst_observed,
	OverwriteData = @overwrite_data,
	DuplicateRules = @duplicate_rules,
	ExtraDetails = @extra_details,
	FutureUseVarchar1 = @extra_column1,
	FutureUseVarchar2 = @extra_column2,
	FutureUseVarchar3 = @extra_column3,
	FutureUseVarchar4 = @extra_column4,
	FutureUseVarchar5 = @extra_column5,
	FutureUseVarchar6 = @extra_column6,
	FutureUseVarchar7 = @extra_column7,
	FutureUseVarchar8 = @extra_column8,
	FutureUseVarchar9 = @extra_column9,
	FutureUseVarchar10 = @extra_column10 ,
	FutureUseVarchar11 = @extra_column11,
	FutureUseVarchar12 = @extra_column12,
	FutureUseVarchar13 = @extra_column13,
	FutureUseVarchar14 = @extra_column14,
	FutureUseVarchar15 = @extra_column15,
	Filters =@filters,
	LastUpdatedOn = getutcdate()
	 where Id = @Id
	
 end





GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateContactMapGroupIteration]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateContactMapGroupIteration] 

@Id int,
@GroupId int,
	@MapId int,
	@CalculatedThreshold numeric(10,2)=null,
	@CalculatedThresholdType int=null,
	@TotalRecords int=null,
	@Details xml ,
	@Status int 


as begin
	update  ContactMapGroupIteration  set GroupId=@GroupId, 
	MapId=@MapId,
	CalculatedThreshold=@CalculatedThreshold,
	CalculatedThresholdType=@CalculatedThresholdType,
	TotalRecords=@TotalRecords,
	Details=@Details,
	Status=@Status,
	LastUpdatedOn=getUTCDate() 
	Where Id=@Id
end






GO
/****** Object:  StoredProcedure [dbo].[Sp_UpdateCustomDNCMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  procedure [dbo].[Sp_UpdateCustomDNCMap] 
	@tenant_id int, 
	@filePath nvarchar(255),
	@campaignId int,
	@starttime time,
	@endtime time,
	@startdate datetime,
	@status int,
	@recurrence int,
	@recurrence_interval int = null,
	@dealerId int ,
	@dNCMapId int

as begin
	Update CustomDNCMapTable set status =@status, LastUpdatedOn=getutcdate(),DealerId=@dealerId,TenantId=@tenant_id,FilePath=@filePath,CampaignId=@campaignId,StartDate=@startdate,StartTime=@starttime,EndTime=@endtime where DNCMapId=@dNCMapId;
end





GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateCustomDNCMaruti]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateCustomDNCMaruti] 

@tenant_id int,
	@dncid int,
	@phoneNumber nvarchar(255),
	@campaignId int,
	@starttime time,
	@endtime time,
	@startdate datetime,
	@enddate datetime,
	@status int,
	@recurrence int,
	@recurrence_interval int = null,
	@next_iterationDate date = null,
	@dealerId int

as begin
	update  CustomDNCMaruti  set NextIterationDate=@next_iterationDate, PhoneNumber=@phoneNumber,CampaignId=@campaignId,StartTime=@starttime,StartDate=@startdate,EndDate=@enddate,EndTime=@endtime,status=@status,Recurrence=@recurrence,RecurrenceInterval=@recurrence_interval,LastUpdatedOn=getUTCDate() Where DNCId=@dncid and TenantId=@tenant_id and DealerId=@dealerId
end





GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateDealer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UpdateDealer] @Id INT,@Name nvarchar(50) ,@Tenant_Id int,@Code nvarchar(100) as
BEGIN
	UPDATE Dealer SET  DealerName = @Name ,TenantId=@Tenant_Id,Dealercode=@Code ,LastUpdatedOn=GETUTCDATE() WHERE DealerId = @Id
END









GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateEmailCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateEmailCampaign]
    @tenant_id int,
	@campaign_id int, 
	@name nvarchar(50), 
	@description nvarchar(255), 
	@state bit, 
	@email_config int,
	@start_time time, 
	@end_time time, 
	@max_batch_size int, 
    @timezone nvarchar(255) = null, 
	@start_date datetime = null, 
	@end_date datetime = null 
as begin
	update EmailCampaign set 
		Name = @name,
		Description = @description, 
		State = @state,
		EmailConfigId = @email_config,
		StartDate = @start_date,
		EndDate = @end_date,
		StartTime = @start_time,
		EndTime = @end_time,
		MaximumBatchSize = @max_batch_size,
		TimeZone = @timezone,
		LastUpdatedOn = GETUTCDATE()
	where EmailCampaignId = @campaign_id and TenantId = @tenant_id
end 












GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateEmailContactMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateEmailContactMap]
	@map_id int,
	@campaign_id int,
	@contact_list_id int,
	@email_column nvarchar(255),
	@attachment xml,
	@subject nvarchar(Max),
	@email_body nvarchar(MAX),
	@placeholders xml,
	@status int,
	@filter_duplicates bit,
	@recurrence_type int,
	@recurrence_interval numeric(10,0) = null,
	@recurrence_unit int = null,
	@recurrence_interval_hours numeric(10,0) = null,
	@recurrence_limit int = null,
	@recurrence_count int = null,
	@next_attempt datetime = null
as begin
	update EmailCampaign_ContactList set
		CampaignId = @campaign_id,
		ContactListId = @contact_list_id, 
		EmailColumn = @email_column,
		EmailBody = @email_body,
		Subject=@subject,
		Attachment=@attachment,
		Placeholders = @placeholders,
		Status = @status,
		FilterDuplicates = @filter_duplicates,
		RecurrenceType = @recurrence_type,
		RecurrenceInterval = @recurrence_interval,
		RecurrenceIntervalUnit = @recurrence_unit,
		RecurrenceIntervalInHours = @recurrence_interval_hours,
		RecurrenceLimit = @recurrence_limit,
		RecurrenceCount = @recurrence_count,
		NextAttemptDateTime = @next_attempt,
		LastUpdatedOn = GETUTCDATE()
	where Id = @map_id
end













GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateEmailStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[SP_UpdateEmailStatus]
	@tenant_id int,
	@status_id int,
	@map_id int,
	@total_records int,
	@invalid_records int,
	@duplicate_records int,
	@records_processed int,
	@end_position nvarchar(255) = null,
	@last_processed_on datetime = null
as begin
	update EmailContactList_Status 
		set TotalRecords = @total_records,
			InvalidRecords = @invalid_records,
			DuplicateRecords = @duplicate_records,
			RecordsProcessed = @records_processed,
			EndPosition = @end_position,
			LastProcessedOn = @last_processed_on,
			LastUpdatedOn = GETUTCDATE()
		where MapId = @map_id and Id = @status_id and TenantId = @tenant_id
end












GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateGlobal_DNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateGlobal_DNC] 
@id uniqueidentifier,
@phone_number nvarchar(50),
@status int
as begin
	update Global_DNC set PhoneNumber = @phone_number,Status = @status,LastUpdatedOn = getutcdate() where DNCId = @id;
end






GO
/****** Object:  StoredProcedure [dbo].[SP_updateGlobalDNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_updateGlobalDNC] 
	@phoneNumber nvarchar(255),
	@dncId uniqueidentifier

as begin
	update GlobalDNC set PhoneNumber=@phoneNumber,LastUpdatedOn=GETUTCDATE() where  DNCId=@dncId
end






GO
/****** Object:  StoredProcedure [dbo].[Sp_UpdateGlobalDNCMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[Sp_UpdateGlobalDNCMap] 
	@dNCMapId INT,
	@filePath NVARCHAR(255),
	@status INT
AS 
BEGIN
	UPDATE GlobalDNCMap SET Status=@status, LastUpdatedOn=getutcdate(), FilePath=@filePath 
	WHERE DNCMapId=@dNCMapId;
END




GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateGroup]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create procedure [dbo].[SP_UpdateGroup] 
	@tenant_id int,
	@group_id int, 
	@name nvarchar(100)
	
as begin
	update GroupMaster set 
		Name = @name,  
		LastUpdatedOn = GETUTCDATE()
	where TenantId = @tenant_id and Id = @group_id
end


GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateHoliday]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateHoliday] 
	@tenant_id int,
	@holiday_id int, 
	@name nvarchar(100), 
	@description nvarchar(255), 
	@start_date date,
	@start_time time,
	@end_time time,
	@end_date date,
	@recurrence int,
	@recurrence_interval numeric(10,2),
	@next_iteration_date date,
	@status int
as begin
	update Holiday set 
		Name = @name, 
		Description = @description, 
		StartDate = @start_date, 
		StartTime = @start_time, 
		EndTime = @end_time, 
		EndDate = @end_date,
		Recurrence = @recurrence,
		RecurrenceInterval = @recurrence_interval,
		NextIterationDate = @next_iteration_date,
		Status = @status, 
		LastUpdatedOn = GETUTCDATE()
	where TenantId = @tenant_id and HolidayId = @holiday_id
end










GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateHolidayCampaignMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateHolidayCampaignMap] @tenant_id int,@map_id int,@holiday_id int,@campaign_id int,@status int, @previous_state bit = null as 
begin
	update CampaignHoliday set 
		Status = @status, 
		CampaignId = @campaign_id, 
		HolidayId = @holiday_id, 
		PreviousState = @previous_state,
		LastUpdatedOn = GETUTCDATE() 
	where Id = @map_id and TenantId = @tenant_id 
end











GO
/****** Object:  StoredProcedure [dbo].[Sp_UpdateImportListSource]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_UpdateImportListSource] @Id int,@name nvarchar(100),@type int,@configuration xml,@dealerId int
as
begin
update ImportList_Source set Name=@name, Type=@type, Configuration=@configuration, LastUpdatedOn = getdate(),DealerId=@dealerId where Id=@Id 
 end










GO
/****** Object:  StoredProcedure [dbo].[Sp_UpdateImportStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[Sp_UpdateImportStatus] 
	@CampaignList_Id int,
	@list_id int,
	@totalRecordImported int,
	@totalDncFiltered int,
	@totalDuplicateFiltered int,
	@totalInvalid int,
	@AttemptedOn datetime, 
	@FinishIndex nvarchar(1000),
	@totalRecords int,
	@preprocessed_on datetime,
	@last_import_failed_records int,
	@status int 
as
begin
	update ContactList_ImportStatus set 
	ListId=@list_id, 
	TotalRecordImported=@totalRecordImported, 
	TotalDncFiltered=@totalDncFiltered, 
	TotalDuplicateFiltered=@totalDuplicateFiltered, 
	TotalInvalid=@totalInvalid, 
	LastAttemptedOn=@AttemptedOn, 
	FinishIndex=@FinishIndex, 
	TotalRecords = @totalRecords,
	LastUpdatedOn = GETUTCDATE(),
	PreProcessedOn = @preprocessed_on,
	LastImportFailedRecords = @last_import_failed_records,
	Status = @status 
	where CampaignList_Id=@CampaignList_Id 
 end









GO
/****** Object:  StoredProcedure [dbo].[Sp_UpdateImportStatusPreviewCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_UpdateImportStatusPreviewCampaign] 
	@CampaignList_Id int,
	@list_id int,
	@totalRecordImported int,
	@totalDncFiltered int,
	@totalDuplicateFiltered int,
	@totalInvalid int,
	@AttemptedOn datetime, 
	@FinishIndex nvarchar(1000),
	@totalRecords int,
	@status int 
as
begin
	update PreviewImportStatus set 
	ListId=@list_id, 
	TotalRecordImported=@totalRecordImported, 
	TotalDncFiltered=@totalDncFiltered, 
	TotalDuplicateFiltered=@totalDuplicateFiltered, 
	TotalInvalid=@totalInvalid, 
	LastAttemptedOn=@AttemptedOn, 
	FinishIndex=@FinishIndex, 
	TotalRecords = @totalRecords,
	Status = @status 
	where CampaignList_Id=@CampaignList_Id 
 end








GO
/****** Object:  StoredProcedure [dbo].[Sp_UpdateMultiListImportStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[Sp_UpdateMultiListImportStatus] 
	@CampaignList_Id int,
	@list_id int,
	@totalRecordImported int,
	@totalDncFiltered int,
	@totalDuplicateFiltered int,
	@totalInvalid int,
	@AttemptedOn datetime, 
	@FinishIndex nvarchar(1000),
	@totalRecords int,
	@status int 
as
begin
	update MultiContactList_ImportStatus set 
	ListId=@list_id, 
	TotalRecordImported=@totalRecordImported, 
	TotalDncFiltered=@totalDncFiltered, 
	TotalDuplicateFiltered=@totalDuplicateFiltered, 
	TotalInvalid=@totalInvalid, 
	LastAttemptedOn=@AttemptedOn, 
	FinishIndex=@FinishIndex, 
	TotalRecords = @totalRecords,
	Status = @status 
	where CampaignList_Id=@CampaignList_Id 
 end









GO
/****** Object:  StoredProcedure [dbo].[SP_updateNationalDNC]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE procedure [dbo].[SP_updateNationalDNC] 
	@tenant_id int, 
	@phoneNumber nvarchar(255),
	@dealerId int ,
	@dncId int

as begin
	update NationalDNC set PhoneNumber=@phoneNumber,LastUpdatedOn=GETUTCDATE() where DealerId=@dealerId and TenantId=@tenant_id and DNCId=@dncId
end








GO
/****** Object:  StoredProcedure [dbo].[SP_UpdatePreviewCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UpdatePreviewCampaign] 
	@tenant_id int,
	@campaign_id int, 
	@name nvarchar(50), 
	@description nvarchar(255), 
	@state bit, 
	@start_time time, 
	@end_time time,  
	@target_country nvarchar(4) = null, 
	@time_zone nvarchar(255) = null, 
	@start_date datetime = null, 
	@end_date datetime = null ,
	@no_of_skills int ,
	@prefix nvarchar = null
as begin
	update PreviewCampaign set 
		Name = @name,
		Description = @description, 
		State = @state,
		StartDate = @start_date,
		EndDate = @end_date,
		StartTime = @start_time,
		EndTime = @end_time,
		TargetCountry = @target_country,
		TimeZone = @time_zone,
		LastUpdatedOn = GETUTCDATE(),
		NoOfSkill =@no_of_skills,
		Prefix=@prefix
	where PreviewCampaignId = @campaign_id and TenantId = @tenant_id
end 








GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateRechurnPolicyMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateRechurnPolicyMap]
	
	@Id int,
	@policyId int,
	@campaignId int,
	@ContactMapId int=null,
	@status int

as begin

	update  RechurnPolicyMap
		set PolicyId=@policyId,Campaign=@campaignId,ContactMap=@ContactMapId,CreatedOn=getutcDate(),Status=@status where Id=@Id
		
end






GO
/****** Object:  StoredProcedure [dbo].[SP_updateRecurrenceSchedule]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_updateRecurrenceSchedule]
	
	@Id int,
	@name nvarchar(255),
	@description nvarchar(255),
	@scheduleType int,
	@frequency int,
	@recurenceInterval numeric(10,2),
	@recurenceUnit int,
	@startDateTime datetime,
	@endDateTime datetime,
	@status int,
	@nextIterationDate date
	

as begin
	declare @output table(Id int)
	update  RecurrenceSchedule set
		Name=@name,Description=@description,ScheduleType=@scheduleType,Frequency=@frequency,RecurrenceInterval=@recurenceInterval,RecurrenceUnit=@recurenceUnit,StartDateTime=@startDateTime,EndDateTime=@endDateTime,Status=@status,LastUpdatedOn=getutcdate(),NextIterationDate=@nextIterationDate where Id=@Id
	
end






GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateRole]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE Procedure [dbo].[SP_UpdateRole]  
    @id int,
	@tenant_id int,
	@featureMap xml,
	@name nvarchar(100)
	as begin 
	update Role_Master set
		FeatureMap=@featureMap,
		Name=@name,
		LastUpdatedOn=getutcdate()
		where RoleId = @id and TenantId=@tenant_id
	end









GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateSession]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateSession] @session_id int, @user_id int, @start_time datetime, @end_time datetime, @extra_details nvarchar(600) as begin
	update UniCampaignSession set UserId = @user_id, StartDateTime = @start_time, EndDateTime = @end_time, ExtraDetails = @extra_details where SessionId = @session_id; 
end











GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateSMSCampaign]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[SP_UpdateSMSCampaign] 
	@tenant_id int,
	@campaign_id int, 
	@name nvarchar(50), 
	@description nvarchar(255), 
	@state bit, 
	@sms_config int,
	@start_time time, 
	@end_time time, 
	@max_batch_size int, 
	@target_country nvarchar(4) = null, 
	@time_zone nvarchar(255) = null, 
	@start_date datetime = null, 
	@end_date datetime = null 
as begin
	update SMSCampaign set 
		Name = @name,
		Description = @description, 
		State = @state,
		SMSConfigId = @sms_config,
		StartDate = @start_date,
		EndDate = @end_date,
		StartTime = @start_time,
		EndTime = @end_time,
		MaximumBatchSize = @max_batch_size,
		TargetCountry = @target_country,
		TimeZone = @time_zone,
		LastUpdatedOn = GETUTCDATE()
	where SMSCampaignId = @campaign_id and TenantId = @tenant_id
end 











GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateSMSContactMap]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UpdateSMSContactMap]
	@map_id int,
	@campaign_id int,
	@contact_list_id int,
	@phone_column nvarchar(255),
	@message nvarchar(MAX),
	@target_country nvarchar(4),
	@placeholders xml,
	@status int,
	@filter_duplicates bit,
	@recurrence_type int,
	@recurrence_interval numeric(10,0) = null,
	@recurrence_unit int = null,
	@recurrence_interval_hours numeric(10,0) = null,
	@recurrence_limit int = null,
	@recurrence_count int = null,
	@next_attempt datetime = null
as begin
	update SMSCampaign_ContactList set
		CampaignId = @campaign_id,
		ContactListId = @contact_list_id, 
		PhoneColumn = @phone_column,
		Message = @message,
		TargetCountry = @target_country,
		Placeholders = @placeholders,
		Status = @status,
		FilterDuplicates = @filter_duplicates,
		RecurrenceType = @recurrence_type,
		RecurrenceInterval = @recurrence_interval,
		RecurrenceIntervalUnit = @recurrence_unit,
		RecurrenceIntervalInHours = @recurrence_interval_hours,
		RecurrenceLimit = @recurrence_limit,
		RecurrenceCount = @recurrence_count,
		NextAttemptDateTime = @next_attempt,
		LastUpdatedOn = GETUTCDATE()
	where Id = @map_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateSMSStatus]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[SP_UpdateSMSStatus]
	@tenant_id int,
	@status_id int,
	@map_id int,
	@total_records int,
	@invalid_records int,
	@duplicate_records int,
	@records_processed int,
	@end_position nvarchar(255) = null,
	@last_processed_on datetime = null
as begin
	update SMSContactList_Status 
		set TotalRecords = @total_records,
			InvalidRecords = @invalid_records,
			DuplicateRecords = @duplicate_records,
			RecordsProcessed = @records_processed,
			EndPosition = @end_position,
			LastProcessedOn = @last_processed_on,
			LastUpdatedOn = GETUTCDATE()
		where MapId = @map_id and Id = @status_id and TenantId = @tenant_id
end











GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateTenant]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[SP_UpdateTenant] @Id INT,@Name nvarchar(50),@Configuration XML ,@IsActive bit as
BEGIN
	UPDATE Tenants SET  Name = @Name, Configuration= @Configuration,IsActive=@IsActive WHERE Id = @Id
END














GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateUserMaster]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[SP_UpdateUserMaster]  
    @user_id int,
    @user_name nvarchar(100),
	@tenant_id int,
	@role_id int,
	@dealer_Id nvarchar(100),
	@password nvarchar(50)
	as begin 
	update User_Master set
	    UserName=@user_name,
		RoleId=@role_id,
		DealerId=@dealer_Id,
		LastUpdatedOn=getutcdate(),
		PasswordUpdatedOn=getutcdate(),
		Password=@password
		where UserId = @user_id  and TenantId=@tenant_id
	end






GO
/****** Object:  StoredProcedure [dbo].[SP_UpdateWrapupReasonCode]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE Procedure [dbo].[SP_UpdateWrapupReasonCode] 
@wrapUpCode_Name nvarchar(50),
@description Nvarchar(255),
@dealer_id int,
@wrapUpId int
as
begin
	update PreviewWarpReasonCode set
		WrapUpCodeName=@wrapUpCode_Name,Description=@description,UpdateOn=GETUTCDATE() where DealerId=@dealer_id and WrapupCodeId=@wrapUpId
end











GO
/****** Object:  StoredProcedure [dbo].[UCCX_Wrapup_summary_report]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[UCCX_Wrapup_summary_report]
  
  as

    begin


	   select ocd.campaignid,
	   case when ocd.callwrapupdata like '% Appointment%' then COUNT(*) else 0 end as Appointment,
	   case when ocd.callwrapupdata like '%Call me later%' then COUNT(*) else 0 end as 'Call me Later',
	   case when ocd.callwrapupdata like '%Voice distortion%' then COUNT(*) else 0 end as 'Voice Distoration',
	   case when ocd.callwrapupdata like '%Do not call%' then COUNT(*) else 0 end as 'Do Not Call',	   
	   case when ocd.callwrapupdata like '%Customer Interested%' then COUNT(*) else 0 end as 'Customer Interested'
	   from OutboundCallDetail ocd where Convert(varchar(10),ocd.callstartdatetime,120)=Convert(varchar(10),GETDATE(),120)
	   group by ocd.campaignid,ocd.callwrapupdata

	end







GO
/****** Object:  StoredProcedure [dbo].[USP_AddLinkedServer]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[USP_AddLinkedServer] @source_server nvarchar(100), @remote_user nvarchar(120), @remote_password nvarchar(200) as begin

	if(not exists(select * from sys.servers where name = @source_server))
	begin
		EXEC master.dbo.sp_addlinkedserver @server =@source_server , @srvproduct=N'SQL Server'
	end

	EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@source_server,@useself=N'False',@locallogin=NULL,@rmtuser=@remote_user,@rmtpassword=@remote_password

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'collation compatible', @optvalue=N'false'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'data access', @optvalue=N'true'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'dist', @optvalue=N'false'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'pub', @optvalue=N'false'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'rpc', @optvalue=N'false'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'rpc out', @optvalue=N'false'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'sub', @optvalue=N'false'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'connect timeout', @optvalue=N'0'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'collation name', @optvalue=null

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'lazy schema validation', @optvalue=N'false'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'query timeout', @optvalue=N'0'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'use remote collation', @optvalue=N'true'

	EXEC master.dbo.sp_serveroption @server=@source_server, @optname=N'remote proc transaction promotion', @optvalue=N'true'
end
















GO
/****** Object:  StoredProcedure [dbo].[USP_AddUniCampaignJob]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[USP_AddUniCampaignJob] 
	@tenant_id int, 
	@source_server nvarchar(100), 
	@source_db nvarchar(MAX), 
	@remote_user nvarchar(120), 
	@remote_password nvarchar(200),
	@sec_source_server nvarchar(100) = null,
	@sec_source_db nvarchar(MAX) = null,
	@sec_remote_user nvarchar(120) = null,
	@sec_remote_password nvarchar(200) = null 
as begin
	declare @tenant_id_str nvarchar(20),
			@destination_db nvarchar(MAX),
			@is_secondary_available bit,
			@job_name nvarchar(max),
			@destination_table nvarchar(max),
			@job_step_query nvarchar(max),
			@sec_job_step_query nvarchar(max),
			@current_user nvarchar(max),
			@agent_table nvarchar(max);
	
	set @is_secondary_available = 0;
	SELECT @destination_db = DB_NAME();
	select @current_user = ORIGINAL_LOGIN();
	set @tenant_id_str = CAST(@tenant_id as nvarchar(20))
	set @job_name = @destination_db+N'_Data_Collect_'+@tenant_id_str;
	-- Create LinkedServer for Primary Side
	EXEC USP_AddLinkedServer @source_server = @source_server, @remote_user = @remote_user, @remote_password = @remote_password
	-- Create LinkedServer for Secondary Side
	IF(@sec_source_server IS NOT NULL AND @sec_source_db IS NOT NULL AND @sec_remote_user IS NOT NULL AND @sec_remote_password IS NOT NULL)
	BEGIN
		set @is_secondary_available = 1;
		EXEC USP_AddLinkedServer @source_server = @sec_source_server,@remote_user = @sec_remote_user, @remote_password = @sec_remote_password
	END
	ELSE BEGIN
		declare @existing_secondary_server nvarchar(100);
		select @existing_secondary_server = SecondaryLinkedServer from DataDump_LastRecoveryKey where TenantId = @tenant_id;
		if(@existing_secondary_server is not null and exists(select * from sys.servers where name = @existing_secondary_server))
		begin
			EXEC master.dbo.sp_dropserver @existing_secondary_server,'droplogins' 
		end
	END
	
	BEGIN TRANSACTION
	
		set @destination_table = 'Outbound_Call_Detail_'+@tenant_id_str
		set @agent_table='UCCEAgent'
	
		if(not exists(select * from DataDump_LastRecoveryKey where TenantId = @tenant_id))
		begin
			insert into DataDump_LastRecoveryKey (TenantId,RecoveryKey,LinkedServer,SecondaryLinkedServer) values(@tenant_id,0,@source_server,@sec_source_server)
		end
		else
		begin
			update DataDump_LastRecoveryKey set LinkedServer = @source_server,SecondaryLinkedServer = @sec_source_server where TenantId = @tenant_id
		end
		if(not exists(select * from msdb.dbo.sysschedules where name = 'UniCampaign_Job_Schedule'))
		begin
			declare @start_date nvarchar(8);
			set @start_date = convert(nvarchar,getdate(),112);
			EXEC msdb.dbo.sp_add_schedule  @schedule_name=N'UniCampaign_Job_Schedule',
				@enabled=1,
				@freq_type=4,
				@freq_interval=1,
				@freq_subday_type=2,
				@freq_subday_interval=30,
				@freq_relative_interval=0,
				@freq_recurrence_factor=0,
				@active_start_date=@start_date,
				@active_end_date=99991231,
				@active_start_time=0,
				@active_end_time=235959
		end
		DECLARE @ReturnCode INT
		SELECT @ReturnCode = 0
		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		END
		DECLARE @jobId BINARY(16);
		SET @jobId = null;
		select @jobId = job_id from msdb.dbo.sysjobs where name = @job_name;
		if(@jobId is null)
		begin
			EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@job_name,
					@enabled=1,
					@notify_level_eventlog=0,
					@notify_level_email=0,
					@notify_level_netsend=0,
					@notify_level_page=0,
					@delete_level=0,
					@description=N'No description available.',
					@category_name=N'Data Collector',
					@owner_login_name=@current_user, @job_id = @jobId OUTPUT
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		set @job_step_query = N'
			if(dbo.TenantState('+@tenant_id_str+') = 1)
			begin
				Declare @Rkey decimal(18,0);
				select @Rkey = RecoveryKey from DataDump_LastRecoveryKey where TenantId = '''+@tenant_id_str+''';
				declare @dynamicSql nvarchar(MAX);
				set @dynamicSql = ''
					insert into ['+@destination_table+']
					(RecoveryKey,DateTime,DateTimeUtc,ImportRuleDateTime,ImportRuleDateTimeUtc,CampaignID,CallResult,CustomerTimeZone,Phone,SkillGroupSkillTargetID,AccountNumber,FirstName,LastName,CallbackDateTime,WrapupData,CallGUID,AgentSkillGroupID,AgentName,AgentLoginName,AgentId,Status)
					select oq.*,Status=1 from openquery(['+@source_server+'],
					 ''''select RecoveryKey,
                    DateTime, DATEADD(second, DATEDIFF(second, GETDATE(), GETUTCDATE()), DD.DateTime) as DateTimeUtc,
					DD.ImportRuleDateTime, DATEADD(second, DATEDIFF(second, GETDATE(), GETUTCDATE()), DD.ImportRuleDateTime) as ImportRuleDateTimeUtc,
					DD.CampaignID , DD.CallResult , DD.CustomerTimeZone ,DD.Phone , DD.SkillGroupSkillTargetID, DD.AccountNumber , DD.FirstName ,DD.LastName ,
					DD.CallbackDateTime , DD.WrapupData ,DD.CallGUID , A.SkillTargetID as AgetSkillTargetID ,p.FirstName + p.LastName as AgentName,p.LoginName as AgentLoginName,A.PeripheralNumber as AgentId from ['+@source_db+'].[dbo].Dialer_Detail DD
					left join ['+@source_db+'].[dbo].Agent A on (DD.AgentPeripheralNumber = A.PeripheralNumber) left join  ['+@source_db+'].[dbo].Person p on (A.PersonID=p.PersonID)
					WHERE EXISTS(select CampaignID from ['+@source_db+'].[dbo].Campaign Cam where Cam.CampaignID = DD.CampaignID and Cam.APIGenerated=''''''''Y'''''''') AND DD.PeripheralID= CASE when DD.AgentPeripheralNumber IS NOT NULL then A.PeripheralID else DD.PeripheralID end 
					AND  RecoveryKey >''+cast(@Rkey as nvarchar(30))+'''''') oq
					'';
					exec(@dynamicSql);
				update  DataDump_LastRecoveryKey Set RecoveryKey = (SELECT COALESCE(Max(RecoveryKey),@Rkey) from ['+@destination_table+']) where TenantId = '''+@tenant_id_str+''';
				
		      declare @dynamicagentSql nvarchar(MAX);
			  set @dynamicagentSql = ''
				insert into ['+@agent_table+'] 
				(SkillTargetID,PersonID,AgentDeskSettingsID,ScheduleID,PeripheralID,EnterpriseName,PeripheralNumber,ConfigParam,Description,Deleted,PeripheralName,TemporaryAgent,AgentStateTrace,SupervisorAgent,ChangeStamp,UserDeletable,DefaultSkillGroup,DepartmentID,DateTimeStamp,LoginName)
              	select * from openquery(['+@source_server+'],
			  ''''select a.SkillTargetID as SkillTargetID,a.PersonID,a.AgentDeskSettingsID,a.ScheduleID,a.PeripheralID,a.EnterpriseName,a.PeripheralNumber,a.ConfigParam,a.Description,a.Deleted,a.PeripheralName,a.TemporaryAgent,a.AgentStateTrace,a.SupervisorAgent,a.ChangeStamp,a.UserDeletable,a.DefaultSkillGroup,a.DepartmentID,a.DateTimeStamp,p.LoginName as LoginName from ['+@source_db+'].[dbo].[Agent] a inner join ['+@source_db+'].[dbo].[Person] p on a.PersonID=p.PersonID  '''') as serverAgents where not exists (select 1 from ['+@agent_table+'] b where serverAgents.SkillTargetID = b.SkillTargetID)'';
              exec(@dynamicagentSql);
				
			end
		';
		declare @job_step_id binary;
		
		set @job_step_id = 1;
		
		if(not exists(select * from msdb.dbo.sysjobsteps where job_id = @jobId and step_id = @job_step_id))
		begin
			
			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Dumping Outbound Data from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=2,
				@on_fail_step_id=0,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, @subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		else
		begin
			EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping Outbound Data from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=2,
				@on_fail_step_id=0,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, 
				@subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = @job_step_id
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		declare @sec_job_step_id binary;
		set @sec_job_step_id = 2;
		IF(@is_secondary_available = 1)
		BEGIN
			set @sec_job_step_query = N'
				if(dbo.TenantState('+@tenant_id_str+') = 1)
				begin
					Declare @Rkey decimal(18,0);
					select @Rkey = RecoveryKey from DataDump_LastRecoveryKey where TenantId = '''+@tenant_id_str+''';
					declare @dynamicSql nvarchar(MAX);
					set @dynamicSql = ''
						insert into ['+@destination_table+']
						(RecoveryKey,DateTime,DateTimeUtc,ImportRuleDateTime,ImportRuleDateTimeUtc,CampaignID,CallResult,CustomerTimeZone,Phone,SkillGroupSkillTargetID,AccountNumber,FirstName,LastName,CallbackDateTime,WrapupData,CallGUID,AgentSkillGroupID,AgentName,AgentLoginName,AgentId,Status)
						select oq.*,Status=1 from openquery(['+@sec_source_server+'],
						''''select RecoveryKey,
						  DateTime, DATEADD(second, DATEDIFF(second, GETDATE(), GETUTCDATE()), DD.DateTime) as DateTimeUtc,
					DD.ImportRuleDateTime, DATEADD(second, DATEDIFF(second, GETDATE(), GETUTCDATE()), DD.ImportRuleDateTime) as ImportRuleDateTimeUtc,
					DD.CampaignID , DD.CallResult , DD.CustomerTimeZone ,DD.Phone , DD.SkillGroupSkillTargetID, DD.AccountNumber , DD.FirstName ,DD.LastName ,
					DD.CallbackDateTime , DD.WrapupData ,DD.CallGUID , A.SkillTargetID as AgetSkillTargetID ,p.FirstName + p.LastName as AgentName,p.LoginName as AgentLoginName,A.PeripheralNumber as AgentId from ['+@sec_source_db+'].[dbo].Dialer_Detail DD
						left join ['+@sec_source_db+'].[dbo].Agent A on (DD.AgentPeripheralNumber = A.PeripheralNumber) left join  ['+@sec_source_db+'].[dbo].Person p on (A.PersonID=p.PersonID)
						WHERE EXISTS(select CampaignID from ['+@sec_source_db+'].[dbo].Campaign Cam where Cam.CampaignID = DD.CampaignID and Cam.APIGenerated=''''''''Y'''''''') AND DD.PeripheralID= CASE when DD.AgentPeripheralNumber IS NOT NULL then A.PeripheralID else DD.PeripheralID end 
						AND  RecoveryKey >''+cast(@Rkey as nvarchar(30))+'''''') oq
						'';
						exec(@dynamicSql);
					update  DataDump_LastRecoveryKey Set RecoveryKey = (SELECT COALESCE(Max(RecoveryKey),@Rkey) from ['+@destination_table+']) where TenantId = '''+@tenant_id_str+''';
				end
			';
			if(not exists(select * from msdb.dbo.sysjobsteps where job_id = @jobId and step_id = @sec_job_step_id))
			begin
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Dumping Outbound Data from Secondary Server',
					@step_id=@sec_job_step_id,
					@cmdexec_success_code=0,
					@on_success_action=1,
					@on_success_step_id=0,
					@on_fail_action=2,
					@on_fail_step_id=0,
					@retry_attempts=0,
					@retry_interval=0,
					@os_run_priority=0, @subsystem=N'TSQL',
					@command=@sec_job_step_query,
					@database_name=@destination_db,
					@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			end
			else
			begin
				EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping Outbound Data from Secondary Server',
					@step_id=@sec_job_step_id,
					@cmdexec_success_code=0,
					@on_success_action=1,
					@on_success_step_id=0,
					@on_fail_action=2,
					@on_fail_step_id=0,
					@retry_attempts=0,
					@retry_interval=0,
					@os_run_priority=0, 
					@subsystem=N'TSQL',
					@command=@sec_job_step_query,
					@database_name=@destination_db,
					@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback				
			end

			EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping Outbound Data from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=4,
				@on_fail_step_id=2,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, 
				@subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			
		END
		ELSE IF(exists(SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = @sec_job_step_id))
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_delete_jobstep @job_id = @jobId, @step_id = @sec_job_step_id
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		END
		
		EXEC @ReturnCode = msdb.dbo.sp_attach_schedule @job_id=@jobId, @schedule_name = N'UniCampaign_Job_Schedule'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		if(not exists (select * from msdb.dbo.sysjobservers where job_id = @jobId))
		begin
			EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end 
	COMMIT TRANSACTION
		GOTO EndSave
	QuitWithRollback:
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:
end




GO
/****** Object:  StoredProcedure [dbo].[USP_CreateTables]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[USP_CreateTables] @tenant_id int
as begin 
	begin transaction
	declare @sms_enabled bit, @email_enabled bit;
	set @sms_enabled =1 ;
	set @email_enabled = 1;
	declare @call_detail_table_name nvarchar(100),
			@email_table_name nvarchar(100),
			@email_result_table_name nvarchar(100),
			@sms_table_name nvarchar(100),
			@sms_result_table_name nvarchar(100),
			@import_multilist_table_name nvarchar(100);

	set @call_detail_table_name = 'Outbound_Call_Detail_';
	set @email_table_name='Email_List_';
	set @email_result_table_name='Email_Result';
	set @sms_table_name = 'SMS_List_';
	set @sms_result_table_name = 'SMS_Result';
	set @import_multilist_table_name = 'Import_MultiList_';

	set @email_table_name=@email_table_name+cast(@tenant_id as nvarchar);
	set @sms_table_name = @sms_table_name + cast(@tenant_id as nvarchar);
	set @call_detail_table_name = @call_detail_table_name +CAST(@tenant_id as nvarchar);
	set @import_multilist_table_name = @import_multilist_table_name + cast(@tenant_id as nvarchar);

	if(not exists(select * from sys.tables where name=@call_detail_table_name))
	begin
		declare @sql nvarchar(MAX);
		set @sql = 'CREATE TABLE [dbo].['+@call_detail_table_name+'](
				Id numeric(25,0) IDENTITY NOT NULL PRIMARY KEY,
				[RecoveryKey] numeric(18,0) NULL,
				[DateTime] [datetime] NULL,
				[DateTimeUtc] [datetime] NULL,
				[ImportRuleDateTime] [datetime] NULL,
				[ImportRuleDateTimeUtc] [datetime] NULL,
				[CampaignID] [int] NULL,
				[CallResult] [int] NULL,
				[CustomerTimeZone] [int] NULL,
				[Phone] [nvarchar](20) NULL,
				[AccountNumber] [nvarchar](50) NULL,
				[FirstName] [nvarchar](50) NULL,
				[LastName] [nvarchar](50) NULL,
				[CallbackDateTime] [datetime] NULL,
				[WrapupData] [nvarchar](max) NULL,
				[CallGUID] [nvarchar](200) NULL,
				[AgentSkillGroupID] [int] NULL,
				[AgentName] [nvarchar](max) NULL,
				[AgentLoginName] [nvarchar](max) NULL,
				[AgentId] [nvarchar](max) NULL,
				[SkillGroupSkillTargetID] [int] NULL,
				[Status] [int] null default 1
			) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];';
			set @sql = @sql + 'CREATE INDEX IDX_OCD_AN_'+cast(@tenant_id as nvarchar)+' on '+@call_detail_table_name+' (AccountNumber ASC);'
			set @sql = @sql + 'CREATE INDEX IDX_OCD_CS_'+cast(@tenant_id as nvarchar)+' on '+@call_detail_table_name+' (CampaignID,Status);'
			set @sql = @sql + 'CREATE INDEX IDX_OCD_P_'+cast(@tenant_id as nvarchar)+' on '+@call_detail_table_name+' (Phone ASC);'
		execute sp_executesql @sql;
	end
	
	if(@sms_enabled = 1 and (not exists(select * from sys.tables where name = @sms_table_name)))
	begin
		declare @sql_sms nvarchar(max);
		set @sql_sms = '
			create table '+@sms_table_name+' (
				Id numeric(20,0) identity(1,1) not null primary key,
				PhoneNumber nvarchar(20) not null,
				PhoneNumberFormatted nvarchar(20) null,
				PlaceholderDetails xml null,
				AttemptId int not null foreign key references SMSContactList_Status(Id),
				MapId int not null foreign key references SMSCampaign_ContactList(Id),
				CampaignId int not null foreign key references SMSCampaign(SMSCampaignId),
				Status int not null,
				SMSResult int not null default 0,
				ProcessedOn datetime null,
				CreatedOn datetime not null default getutcdate(),
				LastUpdatedOn datetime null
			)
		';
		execute sp_executesql @sql_sms;
	end
	if(@email_enabled = 1 and (not exists (Select * from sys.tables where name = @email_table_name)))
	begin
	declare @sql_email nvarchar(max);
	set @sql_email='
			create table '+@email_table_name+'(
				Id numeric(20,0) identity(1,1) not null primary key,
				EmailAddress nvarchar(MAX) not null,
				EmailPlaceholderDetails xml null,
				AttemptId int not null foreign key references EmailContactList_Status(Id),
				MapId int not null foreign key references EmailCampaign_ContactList(Id),
				CampaignId int not null foreign key references EmailCampaign(EmailCampaignId),
				Status int not null,
				EmailResult int not null default 0,
				ProcessedOn datetime null,
				CreatedOn datetime not null default getutcdate(),
				LastUpdatedOn datetime null
			)';
		execute sp_executesql @sql_email;
	end

	if (@@ERROR <> 0 and @@TRANCOUNT > 0)
	rollback transaction
	else
	commit transaction
end


	if(not exists(select * from sys.tables where name = @import_multilist_table_name))
	begin
		declare @sql_import_multilist nvarchar(MAX);
		set @sql_import_multilist = '
			CREATE TABLE [dbo].['+@import_multilist_table_name+'](
	[ImportList_Id] [numeric](20, 0) IDENTITY(1,1)  NOT NULL primary key,
	[Phone01] [nvarchar](20) NULL,
	[Phone01_Formatted] [nvarchar](20) NULL,
	[Phone02] [nvarchar](20) NULL,
	[Phone02_Formatted] [nvarchar](20) NULL,
	[Phone03] [nvarchar](20) NULL,
	[Phone03_Formatted] [nvarchar](20) NULL,
	[Phone04] [nvarchar](20) NULL,
	[Phone04_Formatted] [nvarchar](20) NULL,
	[Phone05] [nvarchar](20) NULL,
	[Phone05_Formatted] [nvarchar](20) NULL,
	[Phone06] [nvarchar](20) NULL,
	[Phone06_Formatted] [nvarchar](20) NULL,
	[Phone07] [nvarchar](20) NULL,
	[Phone07_Formatted] [nvarchar](20) NULL,
	[Phone08] [nvarchar](20) NULL,
	[Phone08_Formatted] [nvarchar](20) NULL,
	[Phone09] [nvarchar](20) NULL,
	[Phone09_Formatted] [nvarchar](20) NULL,
	[Phone10] [nvarchar](20) NULL,
	[Phone10_Formatted] [nvarchar](20) NULL,
	[FirstName] [nvarchar](50) NULL,
	[LastName] [nvarchar](50) NULL,
	[AccountNumber] [nvarchar](50) NULL,
	[TimeZoneBias] [int] NULL,
	[DstObserved] [bit] NULL,
	[Status] [int] NOT NULL,
	[CampaignId] [int] NOT NULL,
	[AttemptId] [int] NULL,
	[MapId] [int] NULL,
	[ExtraData] [xml] NULL,
	[DateTime] [datetime] NULL DEFAULT (getutcdate()),
	[ScheduledDateTime] [datetime] NULL DEFAULT (getutcdate()),
	[PhoneToCallNext] [int] NOT NULL DEFAULT ((1)),
	[CallResult] [int] NOT NULL DEFAULT ((0)),
	[AttemptsMade] [int] NOT NULL DEFAULT ((0)),
	[DialAttempts] [int] NOT NULL DEFAULT ((0)),
	[ImportDateTime] [datetime] NULL DEFAULT (NULL),
				)
			';
		execute sp_executesql @sql_import_multilist;
	end










GO
/****** Object:  StoredProcedure [dbo].[USP_GET_UCCE_SkillGroup]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE procedure [dbo].[USP_GET_UCCE_SkillGroup] 
	@tenant_id int, 
	@source_server nvarchar(100), 
	@source_db nvarchar(MAX), 
	@remote_user nvarchar(120), 
	@remote_password nvarchar(200),
	@sec_source_server nvarchar(100) = null,
	@sec_source_db nvarchar(MAX) = null,
	@sec_remote_user nvarchar(120) = null,
	@sec_remote_password nvarchar(200) = null 
as begin
	declare @tenant_id_str nvarchar(20),
			@destination_db nvarchar(MAX),
			@is_secondary_available bit,
			@job_name nvarchar(max),
			@destination_table nvarchar(max),
			@job_step_query nvarchar(max),
			@sec_job_step_query nvarchar(max),
			@current_user nvarchar(max);
		
	
	set @is_secondary_available = 0;
	SELECT @destination_db = DB_NAME();
	select @current_user = ORIGINAL_LOGIN();
	set @tenant_id_str = CAST(@tenant_id as nvarchar(20))
	set @job_name = @destination_db+N'_Data_Collect_'+'UCCESkillGroup';
	-- Create LinkedServer for Primary Side
	EXEC USP_AddLinkedServer @source_server = @source_server, @remote_user = @remote_user, @remote_password = @remote_password
	-- Create LinkedServer for Secondary Side
	IF(@sec_source_server IS NOT NULL AND @sec_source_db IS NOT NULL AND @sec_remote_user IS NOT NULL AND @sec_remote_password IS NOT NULL)
	BEGIN
		set @is_secondary_available = 1;
		EXEC USP_AddLinkedServer @source_server = @sec_source_server,@remote_user = @sec_remote_user, @remote_password = @sec_remote_password
	END
	ELSE BEGIN
		declare @existing_secondary_server nvarchar(100);
		select @existing_secondary_server = SecondaryLinkedServer from DataDump_LastRecoveryKey_TCD where TenantId = @tenant_id;
		if(@existing_secondary_server is not null and exists(select * from sys.servers where name = @existing_secondary_server))
		begin
			EXEC master.dbo.sp_dropserver @existing_secondary_server,'droplogins' 
		end
	END
	
	BEGIN TRANSACTION
	
		set @destination_table = 'UCCE_Skill_Group'
		
		if(not exists(select * from msdb.dbo.sysschedules where name = 'UniCampaignUCCESkillGroup_Schedule'))
		begin
			declare @start_date nvarchar(8);
			set @start_date = convert(nvarchar,getdate(),112);
			EXEC msdb.dbo.sp_add_schedule  @schedule_name=N'UniCampaignUCCESkillGroup_Schedule',
				@enabled=1,
				@freq_type=4,
				@freq_interval=1,
				@freq_subday_type=2,
				@freq_subday_interval=30,
				@freq_relative_interval=0,
				@freq_recurrence_factor=0,
				@active_start_date=@start_date,
				@active_end_date=99991231,
				@active_start_time=0,
				@active_end_time=235959
		end
		DECLARE @ReturnCode INT
		SELECT @ReturnCode = 0
		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		END
		DECLARE @jobId BINARY(16);
		SET @jobId = null;
		select @jobId = job_id from msdb.dbo.sysjobs where name = @job_name;
		if(@jobId is null)
		begin
			EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@job_name,
					@enabled=1,
					@notify_level_eventlog=0,
					@notify_level_email=0,
					@notify_level_netsend=0,
					@notify_level_page=0,
					@delete_level=0,
					@description=N'No description available.',
					@category_name=N'Data Collector',
					@owner_login_name=@current_user, @job_id = @jobId OUTPUT
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		set @job_step_query = N'
			if(dbo.TenantState('+@tenant_id_str+') = 1)
			begin
		   declare @dynamicAddSkillGroupSql nvarchar(MAX);
			  set @dynamicAddSkillGroupSql = ''
				insert into ['+@destination_table+'] 
				(SkillTargetID,PrecisionQueueID, ScheduleID,PeripheralID,EnterpriseName,PeripheralNumber,PeripheralName,AvailableHoldoffDelay,Priority,BaseSkillTargetID,Extension,SubGroupMaskType,SubSkillGroupMask,ConfigParam,Description,Deleted,MRDomainID,IPTA,DefaultEntry,UserDeletable,ServiceLevelThreshold,ServiceLevelType,BucketIntervalID,ChangeStamp,DepartmentID,DateTimeStamp)
              	select * from openquery(['+@source_server+'],
			  ''''select usg.SkillTargetID,usg.PrecisionQueueID, usg.ScheduleID,usg.PeripheralID,usg.EnterpriseName,usg.PeripheralNumber,usg.PeripheralName,usg.AvailableHoldoffDelay,usg.Priority,usg.BaseSkillTargetID,usg.Extension,usg.SubGroupMaskType,usg.SubSkillGroupMask,usg.ConfigParam,usg.Description,usg.Deleted,usg.MRDomainID,usg.IPTA,usg.DefaultEntry,usg.UserDeletable,usg.ServiceLevelThreshold,usg.ServiceLevelType,usg.BucketIntervalID,usg.ChangeStamp,usg.DepartmentID,usg.DateTimeStamp from ['+@source_db+'].[dbo].[Skill_Group] usg'''') as serverSkillGroups where not exists (select 1 from ['+@destination_table+'] b where serverSkillGroups.SkillTargetID = b.SkillTargetID) and (  serverSkillGroups.Deleted="N" and serverSkillGroups.PrecisionQueueID is null and serverSkillGroups.DefaultEntry = 0 )'';
              exec(@dynamicAddSkillGroupSql);

			declare @dynamicUpdateUCCESkillGroupSql nvarchar(MAX);
			  set @dynamicUpdateUCCESkillGroupSql = ''
			  update UnicampSG set UnicampSG.SkillTargetID=usg.SkillTargetID, UnicampSG.PrecisionQueueID=usg.PrecisionQueueID, UnicampSG.ScheduleID=usg.ScheduleID, UnicampSG.PeripheralID=usg.PeripheralID, UnicampSG.EnterpriseName=usg.EnterpriseName, UnicampSG.PeripheralNumber=usg.PeripheralNumber, UnicampSG.PeripheralName=usg.PeripheralName, UnicampSG.AvailableHoldoffDelay=usg.AvailableHoldoffDelay, UnicampSG.Priority=usg.Priority, UnicampSG.BaseSkillTargetID=usg.BaseSkillTargetID, UnicampSG.Extension=usg.Extension, UnicampSG.SubGroupMaskType=usg.SubGroupMaskType, UnicampSG.SubSkillGroupMask=usg.SubSkillGroupMask, UnicampSG.ConfigParam=usg.ConfigParam, UnicampSG.Description=usg.Description, UnicampSG.Deleted=usg.Deleted,UnicampSG.MRDomainID=usg.MRDomainID,UnicampSG.IPTA=usg.IPTA,UnicampSG.DefaultEntry=usg.DefaultEntry,UnicampSG.UserDeletable=usg.UserDeletable,UnicampSG.ServiceLevelThreshold=usg.ServiceLevelThreshold,UnicampSG.ServiceLevelType=usg.ServiceLevelType,UnicampSG.BucketIntervalID=usg.BucketIntervalID,UnicampSG.ChangeStamp=usg.ChangeStamp,UnicampSG.DepartmentID=usg.DepartmentID,UnicampSG.DateTimeStamp=usg.DateTimeStamp From [dbo].[UCCE_Skill_Group]  as UnicampSG Inner Join ['+@source_server+'].['+@source_db+'].[dbo].[Skill_Group] as usg 
              On (UnicampSG.SkillTargetID=usg.SkillTargetID and UnicampSG.ChangeStamp != usg.ChangeStamp ) or (UnicampSG.SkillTargetID=usg.SkillTargetID and UnicampSG.Deleted!=usg.Deleted)'';
			   exec(@dynamicUpdateUCCESkillGroupSql);
			end
		';
		declare @job_step_id binary;
		
		set @job_step_id = 1;
		
		if(not exists(select * from msdb.dbo.sysjobsteps where job_id = @jobId and step_id = @job_step_id))
		begin
			
			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Dumping UCCE Skill Group from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=2,
				@on_fail_step_id=0,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, @subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		else
		begin
			EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping UCCE Skill Group from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=2,
				@on_fail_step_id=0,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, 
				@subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = @job_step_id
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		declare @sec_job_step_id binary;
		set @sec_job_step_id = 2;
		IF(@is_secondary_available = 1)
		BEGIN
			set @sec_job_step_query = N'
				if(dbo.TenantState('+@tenant_id_str+') = 1)
				begin
				
				 declare @dynamicAddSkillGroupSql nvarchar(MAX);
			  set @dynamicAddSkillGroupSql = ''
				insert into ['+@destination_table+'] 
				(SkillTargetID,PrecisionQueueID, ScheduleID,PeripheralID,EnterpriseName,PeripheralNumber,PeripheralName,AvailableHoldoffDelay,Priority,BaseSkillTargetID,Extension,SubGroupMaskType,SubSkillGroupMask,ConfigParam,Description,Deleted,MRDomainID,IPTA,DefaultEntry,UserDeletable,ServiceLevelThreshold,ServiceLevelType,BucketIntervalID,ChangeStamp,DepartmentID,DateTimeStamp)
              	select * from openquery(['+@sec_source_server+'],
			  ''''select usg.SkillTargetID,usg.PrecisionQueueID, usg.ScheduleID,usg.PeripheralID,usg.EnterpriseName,usg.PeripheralNumber,usg.PeripheralName,usg.AvailableHoldoffDelay,usg.Priority,usg.BaseSkillTargetID,usg.Extension,usg.SubGroupMaskType,usg.SubSkillGroupMask,usg.ConfigParam,usg.Description,usg.Deleted,usg.MRDomainID,usg.IPTA,usg.DefaultEntry,usg.UserDeletable,usg.ServiceLevelThreshold,usg.ServiceLevelType,usg.BucketIntervalID,usg.ChangeStamp,usg.DepartmentID,usg.DateTimeStamp from ['+@sec_source_db+'].[dbo].[Skill_Group] usg where PrecisionQueueID is null and DefaultEntry = 0 '''') as serverSkillGroups where not exists (select 1 from ['+@destination_table+'] b where serverSkillGroups.SkillTargetID = b.SkillTargetID) and (  serverSkillGroups.Deleted="N" and serverSkillGroups.PrecisionQueueID is null and serverSkillGroups.DefaultEntry = 0 )'';
              exec(@dynamicAddSkillGroupSql);
			  
			   declare @dynamicUpdateUCCESkillGroupSql nvarchar(MAX);
			  set @dynamicUpdateUCCESkillGroupSql = ''
			  update UnicampSG set UnicampSG.SkillTargetID=usg.SkillTargetID,UnicampSG.PrecisionQueueID=usg.PrecisionQueueID, UnicampSG.ScheduleID=usg.ScheduleID,UnicampSG.PeripheralID=usg.PeripheralID,UnicampSG.EnterpriseName=usg.EnterpriseName,UnicampSG.PeripheralNumber=usg.PeripheralNumber,UnicampSG.PeripheralName=usg.PeripheralName,UnicampSG.AvailableHoldoffDelay=usg.AvailableHoldoffDelay,UnicampSG.Priority=usg.Priority,UnicampSG.BaseSkillTargetID=usg.BaseSkillTargetID,UnicampSG.Extension=usg.Extension,UnicampSG.SubGroupMaskType=usg.SubGroupMaskType,UnicampSG.SubSkillGroupMask=usg.SubSkillGroupMask,UnicampSG.ConfigParam=usg.ConfigParam,UnicampSG.Description=usg.Description,UnicampSG.Deleted=usg.Deleted,UnicampSG.MRDomainID=usg.MRDomainID,UnicampSG.IPTA=usg.IPTA,UnicampSG.DefaultEntry=usg.DefaultEntry,UnicampSG.UserDeletable=usg.UserDeletable,UnicampSG.ServiceLevelThreshold=usg.ServiceLevelThreshold,UnicampSG.ServiceLevelType=usg.ServiceLevelType,UnicampSG.BucketIntervalID=usg.BucketIntervalID,UnicampSG.ChangeStamp=usg.ChangeStamp,UnicampSG.DepartmentID=usg.DepartmentID,UnicampSG.DateTimeStamp=usg.DateTimeStamp From [dbo].[UCCE_Skill_Group]  as UnicampSG Inner Join ['+@sec_source_server+'].['+@sec_source_db+'].[dbo].[Skill_Group] as usg 
              On (UnicampSG.SkillTargetID=usg.SkillTargetID and UnicampSG.ChangeStamp != usg.ChangeStamp) or (UnicampSG.SkillTargetID=usg.SkillTargetID and UnicampSG.Deleted!=usg.Deleted)'';
			   exec(@dynamicUpdateUCCESkillGroupSql);
				end
			';
			if(not exists(select * from msdb.dbo.sysjobsteps where job_id = @jobId and step_id = @sec_job_step_id))
			begin
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Dumping UCCE Skill Group from  Secondary Server',
					@step_id=@sec_job_step_id,
					@cmdexec_success_code=0,
					@on_success_action=1,
					@on_success_step_id=0,
					@on_fail_action=2,
					@on_fail_step_id=0,
					@retry_attempts=0,
					@retry_interval=0,
					@os_run_priority=0, @subsystem=N'TSQL',
					@command=@sec_job_step_query,
					@database_name=@destination_db,
					@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			end
			else
			begin
				EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping UCCE Skill Group from  Secondary Server',
					@step_id=@sec_job_step_id,
					@cmdexec_success_code=0,
					@on_success_action=1,
					@on_success_step_id=0,
					@on_fail_action=2,
					@on_fail_step_id=0,
					@retry_attempts=0,
					@retry_interval=0,
					@os_run_priority=0, 
					@subsystem=N'TSQL',
					@command=@sec_job_step_query,
					@database_name=@destination_db,
					@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback				
			end

			EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping UCCE Skill Group from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=4,
				@on_fail_step_id=2,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, 
				@subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			
		END
		ELSE IF(exists(SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = @sec_job_step_id))
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_delete_jobstep @job_id = @jobId, @step_id = @sec_job_step_id
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		END
		
		EXEC @ReturnCode = msdb.dbo.sp_attach_schedule @job_id=@jobId, @schedule_name = N'UniCampaignUCCESkillGroup_Schedule'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		if(not exists (select * from msdb.dbo.sysjobservers where job_id = @jobId))
		begin
			EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end 
	COMMIT TRANSACTION
		GOTO EndSave
	QuitWithRollback:
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:
end



















GO
/****** Object:  StoredProcedure [dbo].[USP_GetClickToCallData]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Procedure written to get the click to call data
CREATE PROCEDURE [dbo].[USP_GetClickToCallData](@agentid int)
AS
BEGIN
SET NOCOUNT ON;
	SELECT 
		ImportId,
	    PhoneNumber,
		FirstName,
		LastName,
		Email,
		CreatedOn
	FROM ClicktoCallData;
END









GO
/****** Object:  StoredProcedure [dbo].[USP_GetClickToCallData1]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[USP_GetClickToCallData1](@agentid int)
AS
BEGIN
SET NOCOUNT ON;
	SELECT 
		ID,
	    PhoneNumber_Formatted,
		FirstName,
		LastName
	FROM PreviewCampaignImportList;
END








GO
/****** Object:  StoredProcedure [dbo].[USP_PreviewCampaignImportUniCampaignJob]    Script Date: 18-09-2024 7.30.45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE procedure [dbo].[USP_PreviewCampaignImportUniCampaignJob] 
	@tenant_id int, 
	@source_server nvarchar(100), 
	@source_db nvarchar(MAX), 
	@remote_user nvarchar(120), 
	@remote_password nvarchar(200),
	@sec_source_server nvarchar(100) = null,
	@sec_source_db nvarchar(MAX) = null,
	@sec_remote_user nvarchar(120) = null,
	@sec_remote_password nvarchar(200) = null 
as begin
	declare @tenant_id_str nvarchar(20),
			@destination_db nvarchar(MAX),
			@is_secondary_available bit,
			@job_name nvarchar(max),
			@destination_table nvarchar(max),
			@job_step_query nvarchar(max),
			@sec_job_step_query nvarchar(max),
			@current_user nvarchar(max),
			@agent_table nvarchar(max);
	
	set @is_secondary_available = 0;
	SELECT @destination_db = DB_NAME();
	select @current_user = ORIGINAL_LOGIN();
	set @tenant_id_str = CAST(@tenant_id as nvarchar(20))
	set @job_name = @destination_db+N'_Data_Collect_'+'PreviewCampaignImport';
	-- Create LinkedServer for Primary Side
	EXEC USP_AddLinkedServer @source_server = @source_server, @remote_user = @remote_user, @remote_password = @remote_password
	-- Create LinkedServer for Secondary Side
	IF(@sec_source_server IS NOT NULL AND @sec_source_db IS NOT NULL AND @sec_remote_user IS NOT NULL AND @sec_remote_password IS NOT NULL)
	BEGIN
		set @is_secondary_available = 1;
		EXEC USP_AddLinkedServer @source_server = @sec_source_server,@remote_user = @sec_remote_user, @remote_password = @sec_remote_password
	END
	ELSE BEGIN
		declare @existing_secondary_server nvarchar(100);
		select @existing_secondary_server = SecondaryLinkedServer from DataDump_LastRecoveryKey_TCD where TenantId = @tenant_id;
		if(@existing_secondary_server is not null and exists(select * from sys.servers where name = @existing_secondary_server))
		begin
			EXEC master.dbo.sp_dropserver @existing_secondary_server,'droplogins' 
		end
	END
	
	BEGIN TRANSACTION
	
		set @destination_table = 'PreviewCampaignImportList'
		set @agent_table='UCCEAgent'
	
		if(not exists(select * from DataDump_LastRecoveryKey_TCD where TenantId = @tenant_id))
		begin
			insert into DataDump_LastRecoveryKey_TCD (TenantId,RecoveryKey,LinkedServer,SecondaryLinkedServer) values(@tenant_id,0,@source_server,@sec_source_server)
		end
		else
		begin
			update DataDump_LastRecoveryKey_TCD set LinkedServer = @source_server,SecondaryLinkedServer = @sec_source_server where TenantId = @tenant_id
		end
		if(not exists(select * from msdb.dbo.sysschedules where name = 'UniCampaignPCI_Job_Schedule'))
		begin
			declare @start_date nvarchar(8);
			set @start_date = convert(nvarchar,getdate(),112);
			EXEC msdb.dbo.sp_add_schedule  @schedule_name=N'UniCampaignPCI_Job_Schedule',
				@enabled=1,
				@freq_type=4,
				@freq_interval=1,
				@freq_subday_type=2,
				@freq_subday_interval=30,
				@freq_relative_interval=0,
				@freq_recurrence_factor=0,
				@active_start_date=@start_date,
				@active_end_date=99991231,
				@active_start_time=0,
				@active_end_time=235959
		end
		DECLARE @ReturnCode INT
		SELECT @ReturnCode = 0
		IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Data Collector' AND category_class=1)
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Data Collector'
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		END
		DECLARE @jobId BINARY(16);
		SET @jobId = null;
		select @jobId = job_id from msdb.dbo.sysjobs where name = @job_name;
		if(@jobId is null)
		begin
			EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=@job_name,
					@enabled=1,
					@notify_level_eventlog=0,
					@notify_level_email=0,
					@notify_level_netsend=0,
					@notify_level_page=0,
					@delete_level=0,
					@description=N'No description available.',
					@category_name=N'Data Collector',
					@owner_login_name=@current_user, @job_id = @jobId OUTPUT
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		set @job_step_query = N'
			if(dbo.TenantState('+@tenant_id_str+') = 1)
			begin
				Declare @Rkey decimal(18,0);
				select @Rkey = RecoveryKey from DataDump_LastRecoveryKey_TCD where TenantId = '''+@tenant_id_str+''';		
		      declare @dynamicagentSql nvarchar(MAX);
			  set @dynamicagentSql = ''
			  update PCIL set PCIL.DialAtempts=1, PCIL.AgentLoginName=Agnt.EnterpriseName, PCIL.[Status]=9 ,PCIL.[CallDispostion]=TCD.CallDisposition,PCIL.[RingTime]=TCD.RingTime,PCIL.[DelayTime]=TCD.DelayTime,PCIL.[HoldTime]=TCD.HoldTime,PCIL.[TalkTime]=TCD.TalkTime,PCIL.[WorkTime]=TCD.WorkTime,PCIL.[LocalQTime]=TCD.LocalQTime , PCIL.WrapupData=TCD.WrapupData, PCIL.ImportedTime=TCD.DateTime,PCIL.TCD_RecoveryKey=TCD.RecoveryKey From [dbo].[PreviewCampaignImportList]  as PCIL Inner Join ['+@source_server+'].['+@source_db+'].dbo.Termination_Call_Detail as TCD 
              On (PCIL.ID =TCD.Variable2 and TCD.PeripheralCallType=9 and TCD.RecoveryKey>''+cast(@Rkey as nvarchar(30))+'' and PCIL.[Status]=8 )inner  Join ['+@source_server+'].['+@source_db+'].dbo.Agent as Agnt on TCD.SourceAgentPeripheralNumber=Agnt.PeripheralNumber'';
			   exec(@dynamicagentSql);
			  
			update  DataDump_LastRecoveryKey_TCD Set RecoveryKey = (SELECT COALESCE(Max(TCD_RecoveryKey),@Rkey) from ['+@destination_table+']) where TenantId = '''+@tenant_id_str+''';
				
			end
		';
		declare @job_step_id binary;
		
		set @job_step_id = 1;
		
		if(not exists(select * from msdb.dbo.sysjobsteps where job_id = @jobId and step_id = @job_step_id))
		begin
			
			EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Dumping TCD Data from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=2,
				@on_fail_step_id=0,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, @subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		else
		begin
			EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping TCD Data from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=2,
				@on_fail_step_id=0,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, 
				@subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end
		EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = @job_step_id
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		declare @sec_job_step_id binary;
		set @sec_job_step_id = 2;
		IF(@is_secondary_available = 1)
		BEGIN
			set @sec_job_step_query = N'
				if(dbo.TenantState('+@tenant_id_str+') = 1)
				begin
					Declare @Rkey decimal(18,0);
				select @Rkey = RecoveryKey from DataDump_LastRecoveryKey_TCD where TenantId = '''+@tenant_id_str+''';
			
				
				
		      declare @dynamicagentSql nvarchar(MAX);
			  set @dynamicagentSql = ''
			  
			  update PCIL set PCIL.DialAtempts=1, PCIL.AgentLoginName=Agnt.EnterpriseName, PCIL.[Status]=9 ,PCIL.[CallDispostion]=TCD.CallDisposition,PCIL.[RingTime]=TCD.RingTime,PCIL.[DelayTime]=TCD.DelayTime,PCIL.[HoldTime]=TCD.HoldTime,PCIL.[TalkTime]=TCD.TalkTime,PCIL.[WorkTime]=TCD.WorkTime,PCIL.[LocalQTime]=TCD.LocalQTime , PCIL.WrapupData=TCD.WrapupData, PCIL.ImportedTime=TCD.DateTime,PCIL.TCD_RecoveryKey=TCD.RecoveryKey From [dbo].[PreviewCampaignImportList]  as PCIL Inner Join ['+@sec_source_server+'].['+@sec_source_db+'].dbo.Termination_Call_Detail as TCD 
             On (PCIL.ID =TCD.Variable2 and TCD.PeripheralCallType=9 and TCD.RecoveryKey>''+cast(@Rkey as nvarchar(30))+'' and PCIL.[Status]=8) inner  Join ['+@sec_source_server+'].['+@sec_source_db+'].dbo.Agent as Agnt on TCD.SourceAgentPeripheralNumber=Agnt.PeripheralNumber'';
			   exec(@dynamicagentSql);
			  
			update  DataDump_LastRecoveryKey_TCD Set RecoveryKey = (SELECT COALESCE(Max(TCD_RecoveryKey),@Rkey) from ['+@destination_table+']) where TenantId = '''+@tenant_id_str+''';
				end
			';
			if(not exists(select * from msdb.dbo.sysjobsteps where job_id = @jobId and step_id = @sec_job_step_id))
			begin
				EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Dumping TCD Data from Secondary Server',
					@step_id=@sec_job_step_id,
					@cmdexec_success_code=0,
					@on_success_action=1,
					@on_success_step_id=0,
					@on_fail_action=2,
					@on_fail_step_id=0,
					@retry_attempts=0,
					@retry_interval=0,
					@os_run_priority=0, @subsystem=N'TSQL',
					@command=@sec_job_step_query,
					@database_name=@destination_db,
					@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			end
			else
			begin
				EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping TCD Data from Secondary Server',
					@step_id=@sec_job_step_id,
					@cmdexec_success_code=0,
					@on_success_action=1,
					@on_success_step_id=0,
					@on_fail_action=2,
					@on_fail_step_id=0,
					@retry_attempts=0,
					@retry_interval=0,
					@os_run_priority=0, 
					@subsystem=N'TSQL',
					@command=@sec_job_step_query,
					@database_name=@destination_db,
					@flags=0
				IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback				
			end

			EXEC @ReturnCode = msdb.dbo.sp_update_jobstep @job_id=@jobId, @step_name=N'Dumping TCD Data from Primary Server',
				@step_id=@job_step_id,
				@cmdexec_success_code=0,
				@on_success_action=1,
				@on_success_step_id=0,
				@on_fail_action=4,
				@on_fail_step_id=2,
				@retry_attempts=0,
				@retry_interval=0,
				@os_run_priority=0, 
				@subsystem=N'TSQL',
				@command=@job_step_query,
				@database_name=@destination_db,
				@flags=0
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
			
		END
		ELSE IF(exists(SELECT * FROM msdb.dbo.sysjobsteps WHERE job_id = @jobId and step_id = @sec_job_step_id))
		BEGIN
			EXEC @ReturnCode = msdb.dbo.sp_delete_jobstep @job_id = @jobId, @step_id = @sec_job_step_id
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		END
		
		EXEC @ReturnCode = msdb.dbo.sp_attach_schedule @job_id=@jobId, @schedule_name = N'UniCampaignPCI_Job_Schedule'
		IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		if(not exists (select * from msdb.dbo.sysjobservers where job_id = @jobId))
		begin
			EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
			IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
		end 
	COMMIT TRANSACTION
		GOTO EndSave
	QuitWithRollback:
		IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
	EndSave:
end


















GO
