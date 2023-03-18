using System;

namespace S0142.Common
{
    internal static class Constants
    {
        internal const string ConfigPK = "ELEXONPORTAL";
        internal const string ConfigRK = "S0142";
        internal const string DailyFileList = "https://downloads.elexonportal.co.uk/p114/list?key=<KEY>&date=<RUNDATE>&filter=<FILETYPE>";
        internal const string DownloadFile = "https://downloads.elexonportal.co.uk/p114/download?key=<KEY>&filename=<FILE>";

        // config rowkeys
        internal const string ConfigInterimInitRK = "S0142-II";
        internal const string ConfigFinalInitialRK = "S0142-SF";
        internal const string ConfigFirstReconRK = "S0142-R1";
        internal const string ConfigSecondReconRK = "S0142-R2";
        internal const string ConfigThirdReconRK = "S0142-R3";
        internal const string ConfigFinalReconRK = "S0142-RF";
        internal const string ConfigFinalDisputeRK = "S0142-DF";

        // SAA run types
        internal const string InterimInitial = "II";
        internal const string FinalInitial = "SF";
        internal const string FirstReconciliation = "R1";
        internal const string SecondReconciliation = "R2";
        internal const string ThirdReconciliation = "R3";
        internal const string FinalReconciliation = "RF";
        internal const string FinalDispute = "DF";
    }
}