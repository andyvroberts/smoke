using System;
using System.Runtime.Serialization;

namespace S0142.Common
{
    internal static class Enums
    {
        public enum SettlementsRuns{
            [EnumMember(Value= "II")]
            InterimInitial,
            [EnumMember(Value= "FI")]
            FinalInitial,
            [EnumMember(Value= "R1")]
            FirstReconciliation,
            [EnumMember(Value= "R2")]
            SecondReconciliation,
            [EnumMember(Value= "R3")]
            ThirdReconciliation,
            [EnumMember(Value= "RF")]
            FinalReconciliation,
            [EnumMember(Value= "DR")]
            Dispute,
            [EnumMember(Value= "DF")]
            FinalDispute
        }
    }
}