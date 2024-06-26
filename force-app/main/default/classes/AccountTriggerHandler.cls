public class AccountTriggerHandler {
    
    //Upon Account Creation if Industry is not null and having value as ‘Media’ then populate Rating as Hot.
	public static void populateRating(List<Account> accts)
    {
        for(Account acc : accts)
        {
            if(acc.Industry != null && acc.Industry == 'Media')
            {
                acc.Rating = 'Hot';
            }
        }
    }
    
    //When an account inserts and CopyBillingToShipping (Custom Field) checkbox is checked then automatically copy account billing address into account shipping address.
    public static void populateShippingAddress(List<Account> accts){
        for(Account acc : accts)
        {
            if(acc.CopyBillingToShipping__c)
            {
                if(acc.BillingStreet != null)
                {
                    acc.ShippingStreet = acc.BillingStreet;
                }
                if(acc.BillingState != null)
                {
                    acc.ShippingState = acc.BillingState;
                }
                if(acc.BillingCity != null)
                {
                    acc.ShippingCity = acc.BillingCity;
                }
                if(acc.BillingCountry != null)
                {
                    acc.ShippingCountry = acc.BillingCountry;
                }
                if(acc.BillingPostalCode != null)
                {
                    acc.ShippingPostalCode = acc.BillingPostalCode;
                }
            }
        }
    }

    //Create a related Contact when an Account is created.
    public static void createContact(List<Account> accts)
    {
        List<Contact> conts = new List<Contact>();
        for(Account acc : accts){
            Contact con = new Contact();
            con.FirstName = acc.Name + 'FN';
            con.LastName = acc.Name + 'LN';
            con.AccountId = acc.Id;
            conts.add(con);
        }

        if(!conts.isEmpty())
        {
            insert conts;
        }
    }

    //Create a related Opportunity when an Account is created.
    public static void createOpportunity(List<Account> accts)
    {
        List<Opportunity> opps = new List<Opportunity>();
        for(Account acc : accts){
            Opportunity opp = new Opportunity();
            opp.Name = acc.Name + ' Opportunity';
            opp.AccountId = acc.Id;
            opp.StageName = 'Prospecting';
            opp.CloseDate = Date.today();
            opps.add(opp);
        }

        if(!opps.isEmpty())
        {
            insert opps;
        }
    }

    //On Account create two checkbox fields labeled as Contact and Opportunity.
    //Now when a new Account record is created and if a particular Contact or Opportunity checkbox is checked then create that related record. 
    //Also Opportunity record should be created only if the Account record Active picklist is populated with a Yes.
    public static void createContactOpportunity(List<Account> accts)
    {
        List<Contact> conts = new List<Contact>();
        List<Opportunity> opps = new List<Opportunity>();
        for(Account acc : accts)
        {
            if(acc.Contact__c)
            {
                Contact con = new Contact();
                con.FirstName = acc.Name + 'FN';
                con.LastName = acc.Name + 'LN';
                con.AccountId = acc.Id;

                conts.add(con);
            }

            if(acc.Opportunity__c && acc.Active__c == 'Yes')
            {
                Opportunity opp = new Opportunity();
                opp.Name = acc.Name + ' Opportunity';
                opp.AccountId = acc.Id;
                opp.StageName = 'Prospecting';
                opp.CloseDate = Date.today();

                opps.add(opp);
            }
        }

        if(!conts.isEmpty())
        {
            insert conts;
        }

        if(!opps.isEmpty())
        {
            insert opps;
        }
    }

    //If the Account phone is updated then populate below message in description.
    //Description = Phone is Updated! Old Value : XXX & New Value : XXX
    public static void updateDescription(List<Account> newAccts, Map<Id, Account> oldAccts)
    {
        for(Account acc : newAccts)
        {
            String oldPhone = oldAccts.get(acc.Id).Phone != null ? oldAccts.get(acc.Id).Phone : null;
            if(oldPhone != acc.Phone)
            {
                acc.Description = 'Phone is Updated! Old Value : '+oldPhone+' & New Value : '+acc.Phone;
            }
        }
    }

    //If the Account phone is updated then populate the phone number on all related Contacts (Home Phone field). [Using Map]
    public static void updatePhoneOnRelatedontacts(List<Account> accts, Map<Id, Account> oldAcctsMap)
    {
        Map<Id, Account> eligibleAcctsToUpdate = new Map<Id, Account>();

        for(Account acc : accts)
        {
            if(acc.Phone != oldAcctsMap.get(acc.Id).Phone)
            {
                eligibleAcctsToUpdate.put(acc.Id, acc);
            }
        }

        List<Contact> conts = [SELECT Id, HomePhone, AccountId FROM Contact WHERE AccountId IN :eligibleAcctsToUpdate.keySet()];

        for(Contact con : conts)
        {
            con.HomePhone = eligibleAcctsToUpdate.get(con.AccountId).Phone;
        }

        if(!conts.isEmpty())
        {
            update conts;
        }
    }

    //Write a trigger on Account when Account Active field is updated from ‘Yes’ to ‘No’ then check all opportunities associated with the account. 
    //Update all Opportunities Stage to close lost if stage not equal to close won.
    public static void updateOppStage(List<Account> accts, Map<Id, Account> oldAccMap)
    {
        Set<String> accIds = new Set<String>();
        List<Opportunity> oppToUpdate = new List<Opportunity>();
        for(Account acc : accts)
        {
            if(acc.Active__c == 'No' && acc.Active__c != oldAccMap.get(acc.Id).Active__c)
            {
                accIds.add(acc.Id);
            }
        }

        List<Opportunity> opps = [SELECT Id, AccountId, StageName FROM Opportunity WHERE AccountId IN :accIds];

        for(Opportunity opp : opps)
        {
            if(opp.StageName != 'Closed Won' && opp.StageName != 'Closed Lost')
            {
                opp.StageName = 'Closed Lost';
                oppToUpdate.add(opp);
            }
        }

        if(!oppToUpdate.isEmpty())
        {
            update oppToUpdate;
        }
    }
}