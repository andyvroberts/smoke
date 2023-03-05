using System;

namespace S0142.Common
{
    internal static class Enums
    {
        public enum SettlementsRuns{
            InterimInitial = II,
            FinalInitial = FI,
            FirstReconciliation = R1,
            SecondReconciliation = R2,
            ThirdReconciliation = R3,
            FinalReconciliation = RF,
            Dispute = DR,
            FinalDispute = DF
        }
    }
}