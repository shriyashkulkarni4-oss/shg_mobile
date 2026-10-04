import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "../ui/card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { Avatar, AvatarFallback } from "../ui/avatar";
import { Badge } from "../ui/badge";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "../ui/tabs";
import { User, Mail, Phone, MapPin, Calendar, Edit2, Save, Download, QrCode } from "lucide-react";
import { toast } from "sonner";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "../ui/dialog";
import { collection, doc, getDoc, getDocs, onSnapshot, updateDoc } from "firebase/firestore";
import { db } from "../firebase"; // adjust path if needed
import { useEffect } from "react";
import { useAuth } from "../AuthContext"; // adjust path


interface ProfilePageProps {
  memberData: any;
}

export function ProfilePage({ memberData }: ProfilePageProps) {
  const [isEditing, setIsEditing] = useState(false);
  const [profileData, setProfileData] = useState<any>(null);
  const [loadingProfile, setLoadingProfile] = useState(true);
  const [groupRank, setGroupRank] = useState(0);
  const [totalGroupMembers, setTotalGroupMembers] = useState(0);
  const [goalsAchievedCount, setGoalsAchievedCount] = useState(0);
  const [learningCompletedCount, setLearningCompletedCount] = useState(0);
  const [liveTrustScore, setLiveTrustScore] = useState(memberData?.trustScore?.total || 0);
  const { uid, shgId } = useAuth();

  useEffect(() => {
    if (!uid) return;

    const userRef = doc(db, "users", uid);

    const unsub = onSnapshot(userRef, (snap) => {
      if (snap.exists()) {
        const data = snap.data();
        setProfileData({
          phone: data.phoneNumber || "",
          email: data.email || "",
          address: data.address || "",
          occupation: data.occupation || "",
          annualIncome: data.annualIncome || "",
        });
      } else {
        setProfileData({
          phone: "",
          email: "",
          address: "",
          occupation: "",
          annualIncome: "",
        });
      }

      setLoadingProfile(false);
    });

    return () => unsub();
  }, [uid]);

  useEffect(() => {
    if (!shgId || !uid) return;

    const fetchStats = async () => {
      try {
        // Group rank
        const membersRef = collection(db, "ShgGroups", shgId, "members");
        const snap = await getDocs(membersRef);
        const allMembers = snap.docs.map((d) => ({
          id: d.id,
          trustScore: d.data().trustScore ?? 0,
        }));
        allMembers.sort((a, b) => b.trustScore - a.trustScore);
        const userIndex = allMembers.findIndex((m) => m.id === uid);
        setTotalGroupMembers(allMembers.length);
        setGroupRank(userIndex !== -1 ? userIndex + 1 : 1);

        const currentM = allMembers.find((m) => m.id === uid);
        if (currentM) setLiveTrustScore(currentM.trustScore);

        // Goals achieved
        const goalsSnap = await getDocs(collection(db, "savingGoal", uid, "goals"));
        let achieved = 0;
        goalsSnap.forEach((g) => {
          const d = g.data();
          if (d.goalAchieved || (d.currentAmount && d.targetAmount && d.currentAmount >= d.targetAmount)) {
            achieved++;
          }
        });
        setGoalsAchievedCount(achieved);

        // Learning modules
        const litSnap = await getDoc(doc(db, "FinancialLiteracy", uid));
        if (litSnap.exists()) {
          const lData = litSnap.data();
          let modCount = 0;
          if (lData.modules) {
            Object.values(lData.modules).forEach((m: any) => {
              if (m.completed) modCount++;
            });
          }
          setLearningCompletedCount(modCount);
        }
      } catch (e) {
        console.error("Profile stats fetch error:", e);
      }
    };

    fetchStats();
  }, [shgId, uid]);




const handleSave = async () => {
  try {
    if (!uid) return;

    const userRef = doc(db, "users", uid);

    await updateDoc(userRef, {
      phoneNumber: profileData.phone,
      email: profileData.email,
      address: profileData.address,
      occupation: profileData.occupation,
      annualIncome: Number(profileData.annualIncome),
    });

    toast.success("Profile updated successfully!");
    setIsEditing(false);
  } catch (err) {
    console.error(err);
    toast.error("Failed to update profile");
  }
};




  const handleDownloadPassbook = () => {
    toast.success("Digital passbook downloaded!");
  };

  const getInitials = (name: string) => {
    return name.split(' ').map(n => n[0]).join('').toUpperCase();
  };

if (loadingProfile || !profileData) {
  return (
    <div className="p-6 text-gray-500">
      Loading profile...
    </div>
  );
}


  return (
    <div className="max-w-[1200px] mx-auto space-y-6">
      {/* Header Card with Profile Picture */}
      <Card className="bg-gradient-to-br from-teal-50 to-blue-50 border-teal-200">
        <CardContent className="pt-6">
          <div className="flex flex-col md:flex-row items-center gap-6">
            <Avatar className="w-24 h-24">
              <AvatarFallback className="bg-teal-600 text-white text-3xl">
                {getInitials(memberData.name)}
              </AvatarFallback>
            </Avatar>
            
            <div className="flex-1 text-center md:text-left">
              <h2 className="text-3xl text-gray-900 mb-2">{memberData.name}</h2>
              <div className="flex flex-wrap gap-2 justify-center md:justify-start mb-3">
                <Badge className="bg-teal-100 text-teal-800">Active Member</Badge>
                <Badge className="bg-purple-100 text-purple-800">Trust Score: {memberData.trustScore.total}</Badge>
                <Badge className="bg-blue-100 text-blue-800">{memberData.groupName}</Badge>
              </div>
              <div className="flex flex-col sm:flex-row gap-4 text-sm text-gray-600">
                <div className="flex items-center gap-1 justify-center md:justify-start">
                  <Calendar className="w-4 h-4" />
                  <span>Member since {memberData.memberSince}</span>
                </div>
                <div className="flex items-center gap-1 justify-center md:justify-start">
                  <User className="w-4 h-4" />
                  <span>ID: {memberData.memberId}</span>
                </div>
              </div>
            </div>

            

            <div className="flex gap-2">
              <Dialog>
                <DialogTrigger asChild>
                  <Button variant="outline" className="gap-2">
                    <QrCode className="w-4 h-4" />
                    QR Code
                  </Button>
                </DialogTrigger>
                <DialogContent>
                  <DialogHeader>
                    <DialogTitle>Member QR Code</DialogTitle>
                  </DialogHeader>
                  <div className="flex flex-col items-center gap-4 py-6">
                    <div className="w-64 h-64 bg-white border-2 border-gray-200 rounded-lg flex items-center justify-center">
                      <div className="text-center text-gray-400">
                        <QrCode className="w-32 h-32 mx-auto mb-2" />
                        <p className="text-sm">QR Code Preview</p>
                        <p className="text-xs">ID: {memberData.memberId}</p>
                      </div>
                    </div>
                    <Button onClick={handleDownloadPassbook}>Download QR Code</Button>
                  </div>
                </DialogContent>
              </Dialog>
              
              <Button onClick={handleDownloadPassbook} className="gap-2">
                <Download className="w-4 h-4" />
                Download Passbook
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Profile Tabs */}
      <Tabs defaultValue="personal" className="space-y-4">
        <TabsList className="grid w-full grid-cols-3">
          <TabsTrigger value="personal">Personal Info</TabsTrigger>
          <TabsTrigger value="financial">Financial Summary</TabsTrigger>
          <TabsTrigger value="settings">Settings</TabsTrigger>
        </TabsList>

        {/* Personal Information Tab */}
        <TabsContent value="personal" className="space-y-4">
          <Card>
            <CardHeader>
              <div className="flex justify-between items-center">
                <div>
                  <CardTitle>Personal Information</CardTitle>
                  <CardDescription>Your contact and personal details</CardDescription>
                </div>
                {!isEditing ? (
                  <Button variant="outline" onClick={() => setIsEditing(true)} className="gap-2">
                    <Edit2 className="w-4 h-4" />
                    Edit
                  </Button>
                ) : (
                  <div className="flex gap-2">
                    <Button variant="outline" onClick={() => setIsEditing(false)}>
                      Cancel
                    </Button>
                    <Button onClick={handleSave} className="gap-2">
                      <Save className="w-4 h-4" />
                      Save
                    </Button>
                  </div>
                )}
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="name">Full Name</Label>
                  <Input
                    id="name"
                    value={memberData.name}
                    disabled
                    className="bg-gray-50"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="member-id">Member ID</Label>
                  <Input
                    id="member-id"
                    value={memberData.memberId}
                    disabled
                    className="bg-gray-50"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="phone">Phone Number</Label>
                  <div className="relative">
                    <Phone className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <Input
                      id="phone"
                      value={profileData.phone}
                      onChange={(e) => setProfileData({ ...profileData, phone: e.target.value })}
                      disabled={!isEditing}
                      className={!isEditing ? "bg-gray-50 pl-10" : "pl-10"}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="email">Email Address</Label>
                  <div className="relative">
                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                    <Input
                      id="email"
                      value={profileData.email}
                      onChange={(e) => setProfileData({ ...profileData, email: e.target.value })}
                      disabled={!isEditing}
                      className={!isEditing ? "bg-gray-50 pl-10" : "pl-10"}
                    />
                  </div>
                </div>

                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="address">Address</Label>
                  <div className="relative">
                    <MapPin className="absolute left-3 top-3 w-4 h-4 text-gray-400" />
                    <Input
                      id="address"
                      value={profileData.address}
                      onChange={(e) => setProfileData({ ...profileData, address: e.target.value })}
                      disabled={!isEditing}
                      className={!isEditing ? "bg-gray-50 pl-10" : "pl-10"}
                    />
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="occupation">Occupation</Label>
                  <Input
                    id="occupation"
                    value={profileData.occupation}
                    onChange={(e) => setProfileData({ ...profileData, occupation: e.target.value })}
                    disabled={!isEditing}
                    className={!isEditing ? "bg-gray-50" : ""}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="income">Annual Income</Label>
                  <Input
                    id="income"
                    value={profileData.annualIncome}
                    onChange={(e) => setProfileData({ ...profileData, annualIncome: e.target.value })}
                    disabled={!isEditing}
                    className={!isEditing ? "bg-gray-50" : ""}
                  />
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Group Information */}
          <Card>
            <CardHeader>
              <CardTitle>Group Information</CardTitle>
              <CardDescription>Your SHG membership details</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <p className="text-sm text-gray-600">Group Name</p>
                  <p className="text-gray-900">{memberData.groupName}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Member Since</p>
                  <p className="text-gray-900">{memberData.memberSince}</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Member Role</p>
                  <p className="text-gray-900">Member</p>
                </div>
                <div>
                  <p className="text-sm text-gray-600">Group Registration</p>
                  <p className="text-gray-900">MH/SHG/2023/0145</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Financial Summary Tab */}
        <TabsContent value="financial" className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Card>
              <CardHeader>
                <CardTitle>Savings Overview</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Total Savings</span>
                  <span className="text-gray-900">₹{memberData.financials.totalSavings.toLocaleString('en-IN')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Total Contributed</span>
                  <span className="text-gray-900">₹{memberData.financials.totalContributed.toLocaleString('en-IN')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Interest Earned</span>
                  <span className="text-green-600">₹{memberData.financials.interestEarned.toLocaleString('en-IN')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Monthly Contribution</span>
                  <span className="text-gray-900">₹{memberData.financials.monthlyContribution.toLocaleString('en-IN')}</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Loan Information</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Active Loans</span>
                  <span className="text-gray-900">{memberData.loans.length}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Outstanding Balance</span>
                  <span className="text-blue-600">₹{memberData.financials.loanBalance.toLocaleString('en-IN')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Total Loans Taken</span>
                  <span className="text-gray-900">1</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Loans Completed</span>
                  <span className="text-green-600">0</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Trust Score Details</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Current Score</span>
                  <span className="text-teal-600 text-xl">{liveTrustScore}/100</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Financial Repayment</span>
                  <span className="text-gray-900">{memberData.trustScore.financial}/40</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Timeliness</span>
                  <span className="text-gray-900">{memberData.trustScore.timeliness}/40</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Attendance</span>
                  <span className="text-gray-900">{memberData.trustScore.attendance}/20</span>
                </div>
              </CardContent>
            </Card>

            <Card>
              <CardHeader>
                <CardTitle>Achievements</CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex justify-between">
                  <span className="text-gray-600">Badges Earned</span>
                  <span className="text-gray-900">
                    {goalsAchievedCount > 0 || liveTrustScore >= 70 ? "Active" : "In Progress"}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Learning Modules</span>
                  <span className="text-gray-900">
                    {learningCompletedCount > 0 ? `${learningCompletedCount} Completed` : "In Progress"}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Goals Achieved</span>
                  <span className="text-gray-900">{goalsAchievedCount}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-600">Group Rank</span>
                  <span className="text-orange-600 font-medium">
                    {groupRank > 0 && totalGroupMembers > 0
                      ? `${groupRank} of ${totalGroupMembers}`
                      : "1st of 1"}
                  </span>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>

        {/* Settings Tab */}
        <TabsContent value="settings" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>Notification Preferences</CardTitle>
              <CardDescription>Manage how you receive updates</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="text-gray-900">Payment Reminders</p>
                  <p className="text-sm text-gray-500">Get notified before payment due dates</p>
                </div>
                <input type="checkbox" defaultChecked className="w-5 h-5" />
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="text-gray-900">Meeting Reminders</p>
                  <p className="text-sm text-gray-500">Get notified about upcoming meetings</p>
                </div>
                <input type="checkbox" defaultChecked className="w-5 h-5" />
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="text-gray-900">Group Messages</p>
                  <p className="text-sm text-gray-500">Receive notifications for new messages</p>
                </div>
                <input type="checkbox" defaultChecked className="w-5 h-5" />
              </div>
              <div className="flex items-center justify-between p-3 bg-gray-50 rounded-lg">
                <div>
                  <p className="text-gray-900">Trust Score Updates</p>
                  <p className="text-sm text-gray-500">Get notified when your score changes</p>
                </div>
                <input type="checkbox" defaultChecked className="w-5 h-5" />
              </div>
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Account Security</CardTitle>
              <CardDescription>Keep your account secure</CardDescription>
            </CardHeader>
            <CardContent className="space-y-3">
              <Button variant="outline" className="w-full justify-start">
                Change Password
              </Button>
              <Button variant="outline" className="w-full justify-start">
                Enable Two-Factor Authentication
              </Button>
              <Button variant="outline" className="w-full justify-start">
                View Login History
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

