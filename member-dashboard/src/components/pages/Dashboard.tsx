import { TrustScoreGauge } from "../TrustScoreGauge";
import { FinancialBalanceCard } from "../FinancialBalanceCard";
import { TransactionFeed } from "../TransactionFeed";
import { RemindersCard } from "../RemindersCard";
import { Card, CardContent, CardHeader, CardTitle } from "../ui/card";
import { TrendingUp, Users, Sparkles } from "lucide-react";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { useEffect, useState } from "react";
import { db } from "../firebase";
import { doc, getDoc, query, updateDoc, where } from "firebase/firestore";
interface DashboardProps {
  memberData: any;
}
import { AuthContext, useAuth } from "../AuthContext";
import { useLanguage } from "../../LanguageContext";
import { collection, getDocs } from "firebase/firestore";
import { Chatbot } from "../ChatBot";
export function Dashboard({ memberData }: DashboardProps) {
  const [totalContributed, setTotalContributed] = useState(0);
  const [totalGroupSavings, setTotalGroupSavings] = useState(0);
  const [loanBalance, setLoanBalance] = useState(0);
  const [attendancePresent, setAttendancePresent] = useState(0);
const [totalMeetings, setTotalMeetings] = useState(0);
const [attendanceScore, setAttendanceScore] = useState(0);
  const [totalMonthlyRounds, setTotalMonthlyRounds] = useState(0);
  const [paidMonthlyRounds, setPaidMonthlyRounds] = useState(0);
  const [monthlyRoundScore, setMonthlyRoundScore] = useState(0);
  const [loanDisciplineScore, setLoanDisciplineScore] = useState(0);
  const [loanResponsibilityScore, setLoanResponsibilityScore] = useState(0);
  const [loanRepaymentScore, setLoanRepaymentScore] = useState(0);
  const [totalTrustScore, setTotalTrustScore] = useState(0);
  const [groupRank, setGroupRank] = useState(0);
  const [totalGroupMembers, setTotalGroupMembers] = useState(0);

  const { shgId, uid} = useAuth();
  const { t } = useLanguage();
   useEffect(() => {
  if (!shgId || !uid) return;

  const fetchTotalContributed = async () => {
    let total = 0;

    const roundsSnap = await getDocs(
      collection(db, "ShgGroups", shgId, "monthlyRounds")
    );

    for (const roundDoc of roundsSnap.docs) {
      const contribSnap = await getDocs(
        collection(
          db,
          "ShgGroups",
          shgId,
          "monthlyRounds",
          roundDoc.id,
          "contributions"
        )
      );

      contribSnap.forEach((c) => {
        if (c.id === uid) {
          total += c.data().amountPaid || 0;
        }
      });
    }

    setTotalContributed(total);
  };

  fetchTotalContributed();
}, [shgId, uid]);

useEffect(() => {
  if (!shgId) return;

  const fetchTotalSavings = async () => {
    let total = 0;

    const roundsSnap = await getDocs(
      collection(db, "ShgGroups", shgId, "monthlyRounds")
    );

    for (const roundDoc of roundsSnap.docs) {
      const contribSnap = await getDocs(
        collection(
          db,
          "ShgGroups",
          shgId,
          "monthlyRounds",
          roundDoc.id,
          "contributions"
        )
      );

      contribSnap.forEach((c) => {
        total += c.data().amountPaid || 0;
      });
    }

    setTotalGroupSavings(total);
  };

  fetchTotalSavings();
}, [shgId]);
useEffect(() => {
  if (!shgId || !uid) return;

  const fetchLoanBalance = async () => {
    let total = 0;

    const loansSnap = await getDocs(
      query(
        collection(db, "ShgGroups", shgId, "loans"),
        where("memberId", "==", uid),
        where("status", "==", "APPROVED")
      )
    );

    loansSnap.forEach((doc) => {
      total += Number(doc.data().remainingAmount || 0);
    });

    setLoanBalance(total);
  };

  fetchLoanBalance();
}, [shgId, uid]);
useEffect(() => {
  if (!shgId || !uid) return;

  const fetchAttendance = async () => {
    try {
      const memberRef = doc(db, "ShgGroups", shgId, "members", uid);
      const snap = await getDoc(memberRef);
      const mData = snap.exists() ? snap.data() : {};

      const meetingsSnap = await getDocs(
        collection(db, "ShgGroups", shgId, "meetings")
      );
      const groupMeetingCount = meetingsSnap.size;
      setTotalMeetings(groupMeetingCount);

      // Check if admin stored attendance percentage directly (0-100)
      if (typeof mData.attendance === "number") {
        const score = (mData.attendance / 100) * 20;
        setAttendanceScore(Number(Math.min(20, Math.max(0, score)).toFixed(1)));
        setAttendancePresent(mData.attendancePresent ?? Math.round((mData.attendance / 100) * (groupMeetingCount || 1)));
        return;
      }

      const present = mData.attendancePresent ?? 0;
      const total = mData.attendanceTotal ?? groupMeetingCount;
      setAttendancePresent(present);

      if (total === 0) {
        // If no meetings have occurred yet in the group, member is in perfect standing (20/20)
        setAttendanceScore(20);
      } else {
        const ratio = Math.min(1, present / total);
        setAttendanceScore(Number((ratio * 20).toFixed(1)));
      }
    } catch (e) {
      console.error("Attendance score error:", e);
      setAttendanceScore(20);
    }
  };

  fetchAttendance();
}, [shgId, uid]);

useEffect(() => {
  if (!shgId || !uid) return;

  const fetchMonthlyRoundsScore = async () => {
    try {
      const roundsSnap = await getDocs(
        collection(db, "ShgGroups", shgId, "monthlyRounds")
      );

      const totalRounds = roundsSnap.size;
      let paid = 0;

      for (const roundDoc of roundsSnap.docs) {
        const contribRef = doc(
          db,
          "ShgGroups",
          shgId,
          "monthlyRounds",
          roundDoc.id,
          "contributions",
          uid
        );

        const contribSnap = await getDoc(contribRef);
        if (contribSnap.exists()) {
          paid++;
        }
      }

      setTotalMonthlyRounds(totalRounds);
      setPaidMonthlyRounds(paid);

      if (totalRounds === 0) {
        // No rounds created yet -> perfect base score 40
        setMonthlyRoundScore(40);
      } else {
        const ratio = Math.min(1, paid / totalRounds);
        setMonthlyRoundScore(Number((ratio * 40).toFixed(1)));
      }
    } catch (e) {
      console.error("Monthly rounds score error:", e);
      setMonthlyRoundScore(40);
    }
  };

  fetchMonthlyRoundsScore();
}, [shgId, uid]);

useEffect(() => {
  if (!shgId || !uid) return;

  const calculateLoanTrustScore = async () => {
    try {
      const allLoansSnap = await getDocs(
        collection(db, "ShgGroups", shgId, "loans")
      );

      let totalLoans = 0;
      let totalPrincipal = 0;
      let totalRemaining = 0;
      let onTimeEmis = 0;
      let totalDueOrPaidEmis = 0;

      allLoansSnap.forEach((docSnap) => {
        const loan = docSnap.data();
        if (loan.memberId !== uid) return;

        totalLoans++;
        const principal = Number(loan.principalAmount || loan.amount || 0);
        const remaining = Number(loan.remainingAmount ?? (loan.status === "COMPLETED" ? 0 : principal));
        const paid = Number(loan.paidAmount || (principal - remaining));

        totalPrincipal += principal;
        totalRemaining += remaining;

        if (loan.dueDates && Array.isArray(loan.dueDates)) {
          const now = new Date();
          loan.dueDates.forEach((d: any) => {
            if (!d) return;
            const isPaid = Boolean(d.paid);
            let dueDate: Date | null = null;
            if (d.date) {
              dueDate = typeof d.date.toDate === "function" ? d.date.toDate() : new Date(d.date.seconds ? d.date.seconds * 1000 : d.date);
            }

            const isPastDue = dueDate ? dueDate < now : false;

            if (isPaid) {
              totalDueOrPaidEmis++;
              let paidDate: Date | null = null;
              if (d.paidAt) {
                paidDate = typeof d.paidAt.toDate === "function" ? d.paidAt.toDate() : new Date(d.paidAt.seconds ? d.paidAt.seconds * 1000 : d.paidAt);
              }

              // Within grace period (2 days) is considered on-time
              if (!dueDate || !paidDate || paidDate.getTime() <= dueDate.getTime() + (2 * 86400000)) {
                onTimeEmis++;
              }
            } else if (isPastDue) {
              totalDueOrPaidEmis++;
            }
          });
        }
      });

      // CASE 1: Member has no loans (Zero-debt saver)
      if (totalLoans === 0) {
        setLoanDisciplineScore(24);
        setLoanResponsibilityScore(14);
        setLoanRepaymentScore(38);
        return;
      }

      // CASE 2: Member has active or completed loans
      let emiDisciplineRatio = 1;
      if (totalDueOrPaidEmis > 0) {
        emiDisciplineRatio = Math.max(0, onTimeEmis / totalDueOrPaidEmis);
      }
      const disciplineScore = Number((emiDisciplineRatio * 25).toFixed(1));

      let repaymentRatio = 1;
      if (totalPrincipal > 0) {
        repaymentRatio = Math.min(1, Math.max(0, (totalPrincipal - totalRemaining) / totalPrincipal));
      }
      const completionScore = Number((repaymentRatio * 15).toFixed(1));

      const finalScore = Math.min(40, Math.max(0, Number((disciplineScore + completionScore).toFixed(1))));

      setLoanDisciplineScore(disciplineScore);
      setLoanResponsibilityScore(completionScore);
      setLoanRepaymentScore(finalScore);
    } catch (err) {
      console.error("Loan trust score calculation error:", err);
      setLoanRepaymentScore(38);
    }
  };

  calculateLoanTrustScore();
}, [shgId, uid]);

useEffect(() => {
  const total =
    loanRepaymentScore +
    monthlyRoundScore +
    attendanceScore;

  setTotalTrustScore(Number(total.toFixed(1)));
}, [loanRepaymentScore, monthlyRoundScore, attendanceScore]);

useEffect(() => {
  if (!shgId || !uid) return;
  if (isNaN(totalTrustScore) || totalTrustScore <= 0) return;

  const updateTrustScore = async () => {
    try {
      const memberRef = doc(db, "ShgGroups", shgId, "members", uid);
      await updateDoc(memberRef, {
        trustScore: Number(totalTrustScore.toFixed(1)),
      });
    } catch (err) {
      console.error("Failed to update trustScore:", err);
    }
  };

  updateTrustScore();
}, [shgId, uid, totalTrustScore]);

useEffect(() => {
  if (!shgId || !uid) return;

  const fetchGroupRank = async () => {
    try {
      const membersRef = collection(db, "ShgGroups", shgId, "members");
      const snap = await getDocs(membersRef);

      const allMembers = snap.docs.map((d) => ({
        id: d.id,
        trustScore: d.data().trustScore ?? 0,
      }));

      // Sort by trustScore descending
      allMembers.sort((a, b) => b.trustScore - a.trustScore);

      const total = allMembers.length;
      const userIndex = allMembers.findIndex((m) => m.id === uid);
      const rank = userIndex !== -1 ? userIndex + 1 : 1;

      setTotalGroupMembers(total);
      setGroupRank(rank);
    } catch (err) {
      console.error("Failed to fetch group rank:", err);
    }
  };

  fetchGroupRank();
}, [shgId, uid, totalTrustScore]);

const getOrdinal = (n: number) => {
  const s = ["th", "st", "nd", "rd"];
  const v = n % 100;
  return n + (s[(v - 20) % 10] || s[v] || s[0]);
};

  const currentDisplayTrustScore =
    totalTrustScore > 0 ? totalTrustScore : memberData?.trustScore?.total || 0;

  return (
    <div className="max-w-[1600px] mx-auto space-y-8">
      {/* Quick Stats Bar */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">{t("member_since", "dashboard")}</p>
                <p className="text-2xl text-gray-900">{memberData.memberSince}</p>
              </div>
              <div className="w-12 h-12 rounded-full bg-purple-100 flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-purple-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">{t("monthly_contribution", "dashboard")}</p>
                <p className="text-2xl text-gray-900">₹{totalContributed.toLocaleString("en-IN")}</p>
              </div>
              <div className="w-12 h-12 rounded-full bg-green-100 flex items-center justify-center">
                <TrendingUp className="w-6 h-6 text-green-600" />
              </div>
            </div>
          </CardContent>
        </Card>

        

        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-600">{t("group_rank", "dashboard")}</p>
                <p className="text-2xl text-gray-900">
                  {groupRank > 0 && totalGroupMembers > 0
                    ? `${getOrdinal(groupRank)} of ${totalGroupMembers}`
                    : memberData?.groupStats?.totalMembers > 0
                    ? `1st of ${memberData.groupStats.totalMembers}`
                    : "1st of 1"}
                </p>
              </div>
              <div className="w-12 h-12 rounded-full bg-orange-100 flex items-center justify-center">
                <Users className="w-6 h-6 text-orange-600" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Top Section: Trust Score and Financial Balances */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Trust Score - Takes 2 columns */}
        <div className="lg:col-span-2">
          <TrustScoreGauge
            score={currentDisplayTrustScore}
            financialScore={loanRepaymentScore}
            timelinessScore={monthlyRoundScore}
            attendanceScore={attendanceScore}
          />
        </div>

        {/* Financial Balances - Takes 1 column */}
        <div>
          <FinancialBalanceCard
            totalSavings={Number(totalGroupSavings)}
            loanBalance={Number(loanBalance)}
          />
        </div>
      </div>

      {/* Trust Score History Chart */}
      <Card>
        <CardHeader>
          <CardTitle>{t("trust_score_trend", "dashboard")}</CardTitle>
        </CardHeader>
        <CardContent>
          <ResponsiveContainer width="100%" height={250}>
            <LineChart data={memberData.trustScore.history}>
              <CartesianGrid strokeDasharray="3 3" />
              <XAxis dataKey="month" />
              <YAxis domain={[0, 100]} />
              <Tooltip />
              <Line 
                type="monotone" 
                dataKey="score" 
                stroke="#14b8a6" 
                strokeWidth={3}
                dot={{ fill: '#14b8a6', r: 5 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      {/* Bottom Section: Transaction Feed and Reminders */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Transaction Feed - Takes 2 columns */}
        <div className="lg:col-span-2">
          <TransactionFeed transactions={memberData.transactions.slice(0, 10)} />
        </div>

        {/* Reminders - Takes 1 column */}
        <div>
          <RemindersCard
            nextPaymentDate={memberData.reminders.nextPaymentDate}
            nextPaymentAmount={memberData.reminders.nextPaymentAmount}
            nextMeetingDate={memberData.reminders.nextMeetingDate}
            nextMeetingLocation={memberData.reminders.nextMeetingLocation}
          />
        </div>
      </div>


    </div>
    
  );
  
}