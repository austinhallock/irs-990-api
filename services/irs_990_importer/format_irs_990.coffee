_ = require 'lodash'

{formatInt, formatWebsite, formatFloat, getOrgNameByFiling} = require './helpers'

module.exports = {
  getOrg990Json: (filing) ->
    entityName = getOrgNameByFiling filing

    exemptStatus = if filing.IRS990.parts.part_0?.Orgnztn527Ind \
                   then '527' \
                   else if filing.IRS990.parts.part_0?.Orgnztn49471NtPFInd \
                   then '4947a1' \
                   else if filing.IRS990.parts.part_0?.Orgnztn501c3Ind \
                   then '501c3'
                   # https://github.com/jsfenfen/990-xml-reader/issues/26
                   # else if filing.IRS990EZ.parts.ez_part_0?.Orgnztn501cInd
                   # then "501c#{filing.IRS990EZ.parts.ez_part_0?.Orgnztn501cInd}"

    {
      isProcessed: true
      ein: filing.ReturnHeader.ein
      name: entityName
      city: filing.ReturnHeader.USAddrss_CtyNm
      state: filing.ReturnHeader.USAddrss_SttAbbrvtnCd
      # year: filing.ReturnHeader.RtrnHdr_TxYr
      year: filing.ReturnHeader.RtrnHdr_TxPrdEndDt.substr(0, 4)
      objectId: "#{filing.objectId}"
      exemptStatus: exemptStatus
      mission: filing.IRS990.parts.part_i?.ActvtyOrMssnDsc
      website: formatWebsite filing.IRS990.parts.part_0?.WbstAddrssTxt
      revenue: _.pickBy
        investments: formatInt filing.IRS990.parts.part_i?.CYInvstmntIncmAmt
        grants: formatInt filing.IRS990.parts.part_i?.CYGrntsAndSmlrPdAmt
        ubi: formatInt filing.IRS990.parts.part_i?.TtlGrssUBIAmt # **
        netUbi: formatInt filing.IRS990.parts.part_i?.NtUnrltdBsTxblIncmAmt
        contributionsAndGrants: formatInt filing.IRS990.parts.part_i?.CYCntrbtnsGrntsAmt
        programService: formatInt filing.IRS990.parts.part_i?.CYPrgrmSrvcRvnAmt
        other: formatInt filing.IRS990.parts.part_i?.CYOthrRvnAmt
        total: formatInt filing.IRS990.parts.part_i?.CYTtlRvnAmt

      paidBenefitsToMembers: formatInt filing.IRS990.parts.part_i?.CYBnftsPdTMmbrsAmt
      expenses: _.pickBy
        salaries: formatInt filing.IRS990.parts.part_i?.CYSlrsCmpEmpBnftPdAmt
        professionalFundraising: formatInt filing.IRS990.parts.part_i?.CYTtlPrfFndrsngExpnsAmt
        fundraising: formatInt filing.IRS990.parts.part_i?.CYTtlPrfFndrsngExpnsAmt
        other: formatInt filing.IRS990.parts.part_i?.CYOthrExpnssAmt
        total: formatInt filing.IRS990.parts.part_i?.CYTtlExpnssAmt # **
      assets: _.pickBy
        boy: formatInt filing.IRS990.parts.part_i?.TtlAsstsBOYAmt
        eoy: formatInt filing.IRS990.parts.part_i?.TtlAsstsEOYAmt
      liabilities: _.pickBy
        boy: formatInt filing.IRS990.parts.part_i?.TtlLbltsBOYAmt
        eoy: formatInt filing.IRS990.parts.part_i?.TtlLbltsEOYAmt
      netAssets: _.pickBy
        boy: formatInt filing.IRS990.parts.part_i?.NtAsstsOrFndBlncsBOYAmt
        eoy: formatInt filing.IRS990.parts.part_i?.NtAsstsOrFndBlncsEOYAmt # **

      votingMemberCount: formatInt filing.IRS990.parts.part_i?.VtngMmbrsGvrnngBdyCnt
      independentVotingMemberCount: formatInt filing.IRS990.parts.part_i?.VtngMmbrsIndpndntCnt

      employeeCount: formatInt filing.IRS990.parts.part_i?.TtlEmplyCnt # **
      volunteerCount: formatInt filing.IRS990.parts.part_i?.TtlVlntrsCnt # **
    }

  # 990ez / 990pf
  getOrgJson: (org990, persons, existing990s) ->
    org = {
      # TODO: org type (501..)
      ein: org990.ein
      name: org990.name
      city: org990.city
      state: org990.state
      website: org990.website
      mission: org990.mission
      exemptStatus: org990.exemptStatus
    }

    maxExistingYear = _.maxBy(existing990s, 'year')?.year
    if org990.year >= maxExistingYear or not maxExistingYear
      org.maxYear = org990.year
      org.assets = org990.assets.eoy
      org.liabilities = org990.liabilities.eoy
      org.lastRevenue = org990.revenue.total
      org.lastExpenses = org990.expenses.total
      org.topSalary = _.pick _.maxBy(persons, 'compensation'), [
        'name', 'title', 'compensation'
      ]

    org

  # TODO: mark people from previous years as inactive people for org
  getOrgPersonsJson: (filing) ->
    entityName = getOrgNameByFiling filing

    _.map filing.IRS990.groups.Frm990PrtVIISctnA, (person) ->
      businessName = person.BsnssNmLn1Txt
      if person.BsnssNmLn2Txt
        businessName += " #{person.BsnssNmLn2Txt}"
      {
        name: person.PrsnNm or businessName
        ein: filing.ReturnHeader.ein
        entityName: entityName
        entityType: 'org'
        year: filing.ReturnHeader.RtrnHdr_TxPrdEndDt.substr(0, 4)
        isBusiness: Boolean businessName
        title: person.TtlTxt
        weeklyHours: formatFloat person.AvrgHrsPrWkRt or person.AvrgHrsPrWkRltdOrgRt
        compensation: formatInt person.RprtblCmpFrmOrgAmt
        relatedCompensation: formatInt person.RprtblCmpFrmRltdOrgAmt
        otherCompensation: formatInt person.OthrCmpnstnAmt
        isOfficer: person.OffcrInd is 'X'
        isFormerOfficer: person.FrmrOfcrDrctrTrstInd is 'X'
        isKeyEmployee: person.KyEmplyInd is 'X'
        isHighestPaidEmployee: person.HghstCmpnstdEmplyInd is 'X'
      }

}
