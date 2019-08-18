public class OA_GResponse {
public class Query
{
    public String startdate;
    public String enddate;
    public String ids;
    public String dimensions;
    public List<String> metrics;
    public integer startindex;
    public integer maxresults;
}

public class ProfileInfo
{
    public String profileId;
    public String accountId;
    public String webPropertyId;
    public String internalWebPropertyId;
    public String profileName;
    public String tableId;
}

public class ColumnHeader
{
    public String name;
    public String columnType;
    public String dataType;
}

public class TotalsForAllResults
{
    public String gatotalEvents;
    public String gauniqueEvents;
    public String gaeventValue;
    public String gaavgEventValue;
    public String gasessionsWithEvent;
    public String gaeventsPerSessionWithEvent;
}


    public String kind;
    public String id;
    public Query query;
    public integer itemsPerPage;
    public integer totalResults;
    public String selfLink;
    public ProfileInfo profileInfo;
    public boolean containsSampledData;
    public List<ColumnHeader> columnHeaders;
    public TotalsForAllResults totalsForAllResults;
    public List<List<String>> rows;
    
}