package com.ibm.money.ibm_money_app

import java.io.ByteArrayOutputStream
import org.apache.poi.poifs.crypt.EncryptionInfo
import org.apache.poi.poifs.crypt.EncryptionMode
import org.apache.poi.poifs.filesystem.POIFSFileSystem
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test

class ExcelDecryptorTest {
    @Test
    fun decryptsPasswordProtectedOfficePackage() {
        val expected = byteArrayOf(0x50, 0x4b, 0x03, 0x04, 1, 2, 3, 4)
        val encrypted = encryptedPackage(expected, "test-password")

        assertArrayEquals(expected, ExcelDecryptor.decrypt(encrypted, "test-password"))
    }

    @Test(expected = InvalidExcelPasswordException::class)
    fun rejectsWrongPassword() {
        val encrypted = encryptedPackage(byteArrayOf(0x50, 0x4b, 1, 2), "correct")

        ExcelDecryptor.decrypt(encrypted, "wrong")
    }

    @Test
    fun decryptsProvidedTossWorkbookWhenAvailable() {
        val path = System.getenv("TOSS_TEST_FILE") ?: return
        val password = System.getenv("TOSS_TEST_PASSWORD") ?: return

        val decrypted = ExcelDecryptor.decrypt(java.io.File(path).readBytes(), password)

        assertEquals(0x50, decrypted[0].toInt() and 0xff)
        assertEquals(0x4b, decrypted[1].toInt() and 0xff)
    }

    private fun encryptedPackage(bytes: ByteArray, password: String): ByteArray {
        POIFSFileSystem().use { fileSystem ->
            val info = EncryptionInfo(EncryptionMode.agile)
            val encryptor = info.encryptor
            encryptor.confirmPassword(password)
            encryptor.getDataStream(fileSystem).use { output -> output.write(bytes) }
            return ByteArrayOutputStream().use { output ->
                fileSystem.writeFilesystem(output)
                output.toByteArray()
            }
        }
    }
}
