import x10.util.concurrent.AtomicInteger;
import x10.io.Console;

public class ReadersWriterLock {
    val readers:AtomicInteger = new AtomicInteger(0);
    val writers:AtomicInteger = new AtomicInteger(0);
    val waiters:AtomicInteger = new AtomicInteger(0);

    public def lock(i:Int, w:Boolean)
    {
        if (w) writeLock(i);
        else readLock(i);
    }

    private def writeLock(i:Int)
    {
        waiters.incrementAndGet();
        while (true) {
            atomic if (writers.get() == 0 && readers.get() == 0) {
                writers.incrementAndGet();
                break;
            }
        }
        waiters.decrementAndGet();
    }

    private def readLock(i:Int)
    {
        while (writers.get() > 0 || waiters.get() > 0);
        readers.incrementAndGet();
    }

    public def unlock(i:Int, w:Boolean)
    {
        if (w) writeUnlock(i);
        else readUnlock(i);
    }

    private def writeUnlock(i:Int)
    {
        writers.decrementAndGet();
    }

    private def readUnlock(i:Int)
    {
        readers.decrementAndGet();
    }

    private static def busywait(n:Int)
    {
        for (i in 0..(n * 1000))
            ;
    }

    public static def main(argv:Array[String]{self.rank==1})
    {
        val x = new ReadersWriterLock();
        val y:Cell[Int] = new Cell[Int](0);

        finish for (i in 1..100) async {
            /* do some waiting to scramble the asyncs a bit */
            busywait(500);

            /* grab a read lock for a bit */
            x.lock(i, false);
            busywait(500);
            /* Console.OUT.println("N: " + y()); */
            x.unlock(i, false);

            /* do some writing */
            x.lock(i, true);
            val yy = i % 2 == 0 ? y() + 10 : y() - 5;
            busywait(5000);
            y() = yy;
            /* Console.OUT.println("N: " + y()); */
            x.unlock(i, true);

            /* read lock some more */
            x.lock(i, false);
            busywait(500);
            /* Console.OUT.println("N: " + y()); */
            x.unlock(i, false);

            /* do some more writing */
            x.lock(i, true);
            val yyy = i % 2 == 0 ? y() - 10 : y() + 5;
            busywait(5000);
            y() = yyy;
            /* Console.OUT.println("N: " + y()); */
            x.unlock(i, true);
        }

        /* if locks worked, y() will be zero */
        if (y() == 0) Console.OUT.println("TEST PASSED");
        else Console.OUT.println("TEST FAILED");

    }
}
