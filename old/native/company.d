module company;

import godot, godot.control;

import std.algorithm;
import std.conv;
import std.math;
import std.sumtype;

enum Week { start }

bool isStartOfMonth(Week week)
{
	return (cast(uint)week % 4) == 0;
}

struct SEPAMandat
{
	int toAccount;
	Invoice.Field[] fields;
	PaymentDetail paymentTemplate;
}

struct Discount
{
	int payWithin;
	float percentage = 0;

	enum standard = Discount(1, 0.02);
}

struct RetryCounter
{
	int retriesBeforePenalty;
	int retryWeekLength = 1;
	float penaltyPercentage = 0;
	int remainingPenalties;
	int appealCount;
	float appealChance = 0.5;

	enum RetryCounter finanzamt = RetryCounter(1, 1, 0.12, 2, 4, 0.9);
	enum RetryCounter strict = RetryCounter(1, 1, 0.04, 1, 1, 0.5);
	enum RetryCounter regular = RetryCounter(3, 1, 0.025, 2, 2, 0.75);
	enum RetryCounter lean = RetryCounter(3, 2, 0.02, 3, 3, 1.0);
}

struct PaymentDetail
{
	Discount discount;

	int remainingWeeks;
	RetryCounter internalRetries;

	enum PaymentDetail strict4Week = PaymentDetail(Discount.init, 4, RetryCounter.strict);
	enum PaymentDetail regular4Week = PaymentDetail(Discount.init, 4, RetryCounter.regular);
	enum PaymentDetail lean4Week = PaymentDetail(Discount.standard, 4, RetryCounter.lean);
}

struct Invoice
{
	struct Field
	{
		string reason;
		long amountNet;
		float tax = 0.19;

		long amountGross() const @property
		{
			return cast(long)floor(amountNet * (1 + tax));
		}
	}

	enum Reason
	{
		regular,
		failedMandat,
		tax,
	}

	int invoiceNo;
	int toAccount;
	Field[] fields;
	PaymentDetail paymentDetail;
	Reason reason;
	bool paid;

	static Invoice fromMandat(SEPAMandat mandat)
	{
		auto id = customer(mandat.toAccount).generateInvoiceID();
		Invoice i = {
			invoiceNo: id,
			toAccount: mandat.toAccount,
			fields: mandat.fields,
			paymentDetail: mandat.paymentTemplate,
			reason: Reason.failedMandat,
			paid: false
		};
		return i;
	}
}

long sumNet(Invoice.Field[] fields)
{
	return fields.map!"a.amountNet".sum;
}

long sumGross(Invoice.Field[] fields)
{
	return fields.map!"a.amountGross".sum;
}

struct IncomeInvoice
{
	enum Reason
	{
		payment,
		doublePaymentRefund,
		tax,
	}

	Reason reason;
	int fromAccount;
	Invoice.Field[] fields;
}

struct Customer
{
	@disable this(this);

	int id;
	string name;
	int invoiceCounter;

	int[] unpaidInvoices;

	int generateInvoiceID()
	{
		auto id = ++invoiceCounter;
		unpaidInvoices ~= id;
		return id;
	}

	void paidInvoice(Company company, int invoiceNumber)
	{
		auto i = unpaidInvoices.countUntil(invoiceNumber);
		if (i == -1)
			company.refundDoublePayment(id, invoiceNumber);
		else
			unpaidInvoices = unpaidInvoices.remove(i);
	}
}

__gshared Customer[] customers = [
	Customer(0, "Möbel GmbH"),
	Customer(1, "Finanzamt"),
];

static assert(customers.enumerate.all!(kv => kv.key == kv.value.id));

ref Customer customer(int id)
{
	if (id < 0 || id >= customers.length)
		throw new Exception("Cannot find customer");
	return customers[id];
}

struct Letter
{
	struct Ad
	{
		string text;
	}

	string from;
	string subject;
	Week week;
	SumType!(Invoice, IncomeInvoice, Ad) content;
	bool read;

	static Letter from(Invoice invoice, Week week)
	{
		Letter l = {
			from: customer(invoice.toAccount).name,
			subject: "Invoice for services",
			week: week,
			content: invoice
		};
		return l;
	}

	static Letter from(IncomeInvoice invoice, Week week)
	{
		Letter l = {
			from: "GlobalBank Inc.",
			subject: "Received Payment from " ~ customer(invoice.fromAccount).name,
			week: week,
			content: invoice
		};
		return l;
	}

	static Letter ad(Week week, string from, string subject, string content)
	{
		Letter l = {
			from: from,
			subject: subject,
			week: week,
			content: Ad(content)
		};
		return l;
	}
}

struct Transaction
{
	int otherAccount;
	long amount;
	string reason;
	GameDate date;
}

struct GameDate
{
	Week week;
	ubyte weekday;
}

class Company : GodotScript!Control
{
	long moneyBank = 1000_00;
	Transaction[] bankTransactions;

	Invoice[] invoiceHistory;

	IncomeInvoice[] queuedIncome;
	Invoice[] queuedInvoices;
	Letter[] letters;
	SEPAMandat[] sepaMandats;

	@Method void nextWeek(int week)
	{
		auto weekTyped = cast(Week)week;
		postInvoices(weekTyped);
		processIncome(weekTyped);
		processMandats(weekTyped);
	}

	@Method void processWeekday(int week, int weekday)
	{
		assert(weekday >= 0 && weekday < 7);
		if (weekday == 2)
			payMandats(GameDate(cast(Week)week, cast(ubyte)weekday));
	}

	void postInvoices(Week week)
	{
		invoiceHistory ~= queuedInvoices;
		letters ~= queuedInvoices.map!(i => Letter.from(i)).array;
		queuedInvoices.length = 0;
	}

	void processMandats(Week week)
	{
		if (!week.isStartOfMonth)
			return;

		foreach (mandat; sepaMandats)
			queuedInvoices ~= Invoice.fromMandat(this, mandat);
	}

	void processIncome(Week week)
	{
		if (!week.isStartOfMonth)
			return;

		foreach (income; queuedIncome)
		{
			letters ~= Letter.from(income);
			receiveFrom(income.fromAccount, income.fields.sumGross,
				income.reason, GameDate(week, 0));
		}
	}

	void payMandats(GameDate date)
	{
		foreach_reverse (i, ref invoice; queuedInvoices)
		{
			if (moneyBank >= invoice.sumGross)
			{
				payTo(invoice.toAccount, invoice.sumGross,
					"Invoice " ~ customer(invoice.toAccount).name ~ " #" ~ invoice.invoiceNo.to!string,
					date);
				queuedInvoices = queuedInvoices.remove(i);

				customer(invoice.toAccount).paidInvoice(this, invoice.invoiceNo);
			}
		}
	}

	void payTo(int account, long amount, string reason, GameDate date)
	{
		assert(amount >= 0);
		bankTransactions ~= Transaction(account, -amount, reason, date);
		moneyBank -= amount;
	}

	void receiveFrom(int account, long amount, string reason, GameDate date)
	{
		assert(amount >= 0);
		bankTransactions ~= Transaction(account, amount, reason, date);
		moneyBank += amount;
	}

	void refundDoublePayment(int account, int invoiceNumber)
	{
		auto invoice = findInvoice(account, invoiceNumber);
		auto income = IncomeInvoice(IncomeInvoice.Reason.doublePaymentRefund, account,
			invoice.fields);
		queuedIncome ~= income;
	}

	Invoice findInvoice(int account, int invoiceNumber)
	{
		foreach (invoice; invoiceHistory)
			if (invoice.invoiceNo == invoiceNumber && invoice.toAccount == account)
				return invoice;
		throw new Exception("Cant find invoice");
	}
}
